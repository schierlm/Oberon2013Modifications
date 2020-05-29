KernelDebugger - Debug and inspect one RISC5 machine from another one via serial link

Description
-----------

**NOTE**: Unlike other modifications, this modification is not standalone. It requires that
you applied the [DoubleTrap](../DoubleTrap/README.md), [TrapBacktrace](../TrapBacktrace/README.md),
[ZeroLocalVariables](../ZeroLocalVariables/README.md), [ORInspect](../ORInspect/README.md)
and [ORStackInspect](../ORStackInspect/README.md) modifications before this modification.

Compared with modern development environments, debugging RISC5 Oberon programs is limited.
While the [ORInspect](../ORInspect/README.md) and [ORStackInspect](../ORStackInspect/README.md)
This may also be caused by the limited hardware these programs run on. Modern PC processors
have hardware support for breakpoints, virtualization, pre-emptive multitasking and other
features that make debugging easy. On the other hand, these features also add vast complexity
to the architecture and are therefore not desirable on a "minimal" architecture.

This modification explores how real-time debugging can be made possible on an unmodified
RISC5 CPU.

Due to memory constraints and no multitasking, running the debugger on the same machine as
the debuggee is tricky. Therefore, we take a different approach here, which is also known
from low-level driver development: The debuggee is running on one RISC5 machine, and the
debugger on another one. Both are connected via a serial link.

A debug stub written in Assembly is invoked whenever a breakpoint is hit (and if you set a
breakpoint on the trap handler, also when a trap occurs) and takes care to communicate the
CPU state to the debugger via serial link. Once you decide to continue execution, the stub
jumps back into the real code. Communication between the debugger and the debug stub happens
via a debug context. Before returning, all register state needs to be restored. Some special
registers (`H` and `Flags`) cannot be set directly, so they have to be set via side effects.
This requires a scratch register, which may not be used by the program or it would be impossible
to step over instructions using it. For this purpose, the `R11` register is used. To make the
debug context available at all times, its address is stored in the R10 register all the time.
Therefore the compiler needs to be patched to reserve these two registers. This results in fewer
registers available to the program, but apart from one location in `TextFrames.Mod` that can
easily be rewritten, more than 10 general registers are never needed.

Breakpoints are implemented by storing the original instruction and replacing it by a jump
instruction. As the `BL` instruction clobbers both `R15` and the flag register, instead a
static jump is used, which jumps into a different trampoline for each breakpoint. The
trampoline will record the flags and the origin of the breakpoint, and then jump to the general
debug stub which will save the rest of the state, lookup the breakpoint's handler (written in Oberon)
and invoke it. For testing the debug stub and breakpoints (if they work as expected on your own
RISC5 machine), a `DebugStubTest.Mod` module is available.

On the debuggee system, make sure that you compile all relevant modules with debug symbols
(using the `/d` switch). Then start the DebugServer using `DebugServer.Run`. On the debugger system,
you start by running `DebugTools.UpdateModuleList`: This command will check the list of loaded
modules on the debuggee. All corresponding `.Mod`, `.rsc`, `.ssy` and `.isy` files will be copied
to the debuggee machine if they are not already there, replacing the last character of the extension
with an 'R'. Therefore, this can take a while when you run it for the first time.

Afterwards, you can use the command listed in `Debugger.Tool` to debug the debuggee machine. Some
commands are only available when you are in a breakpoint, others only when you are not in a breakpoint.
If you run such a command in an invalid state, `Invalid state` is printed to the debugger machine's Log.

Breakpoints can either be set at raw memory locations, or at the beginning of command PROCEDUREs. If
you want to have a breakpoint elsewhere and do not want to search through disassembly, just add a call
to an empty command PROCEDURE there and set a breakpoint on it.

In case you manage to cause a TRAP in the debugger, the serial port buffer may contain some bytes
you don't want there. In that case you can call `DebugClient.Drain` before trying again.


Installation
------------

- Apply [DoubleTrap](../DoubleTrap/README.md), [TrapBacktrace](../TrapBacktrace/README.md),
  [ZeroLocalVariables](../ZeroLocalVariables/README.md), [ORInspect](../ORInspect/README.md)
  and [ORStackInspect](../ORStackInspect/README.md), if not already applied.

- Apply [`RS232.patch`](RS232.patch) to `RS232.Mod`.

- Apply [`ReserveRegisters.patch`](ReserveRegisters.patch) to `ORG.Mod`, `ORP.Mod`
  and `TextFrames.Mod`.

- Optionally apply [`ReserveRegistersExtra.patch`](ReserveRegistersExtra.patch) to
  `OnScreenKeyboard.Mod`, `Trappy.Mod` (from RobustTrapViewer) and `TextFramesU.Mod`
  (from UTF8CharsetLite), if you want to use these modifications.

- Push the new modules.

- Recompile the whole system, as the registers need to stay reserved everywhere:

      ORP.Compile Kernel.Mod/s FileDir.Mod/s Files.Mod/s Modules.Mod/s ~
      ORL.Link Modules ~
      ORL.Load Modules.bin ~

      ORP.Compile Input.Mod/s Display.Mod/s Viewers.Mod/s ~
      ORP.Compile Fonts.Mod/s Texts.Mod/s ~
      ORP.Compile Oberon.Mod/s ~
      ORP.Compile MenuViewers.Mod/s ~
      ORP.Compile TextFrames.Mod/s ~
      ORP.Compile System.Mod/s ~
      ORP.Compile Edit.Mod/s ~
      ORP.Compile ORS.Mod/s ORB.Mod/s ~
      ORP.Compile ORG.Mod/s ORP.Mod/s ~

      ORP.Compile RS232.Mod/s DebugStub.Mod/s DebugStubTest.Mod/s ~
      ORP.Compile DebugConstants.Mod/s DebugClient.Mod/s DebugServer.Mod/s ~
      ORP.Compile DebugTools.Mod/s DebugInspect/s ~

- Clone the machine (or do the same on another machine), restart both clones.

- In the debuggee, recompile all modules that you want to inspect, with the /d switch.

- In the debuggee, run `DebugServer.Run`.

- In the debugger, run `DebugTools.UpdateModuleList`.

- In the debugger, open `Debugger.Tool` and use the commands inside to debug the debuggee.
