ORStackInspect - Inspect stack variables when printing a backtrace

Description
-----------

**NOTE**: Unlike other modifications, this modification is not standalone. It requires that
you applied the [DoubleTrap](../DoubleTrap/README.md), [TrapBacktrace](../TrapBacktrace/README.md),
[ZeroLocalVariables](../ZeroLocalVariables/README.md) and [ORInspect](../ORInspect/README.md)
modifications before this modification.

Debugging capabilities of Project Oberon are limited. You can output things to System.Log
or you can get raw memory dumps. This is far from what you can expect from other debuggers.
The [ORInspect](../ORInspect/README.md) improves this situation, so that you can inspect
global and heap variables.

To extend this inspection capabilities to variables on the stack (when printing a stack
backtrace), this modification adds an extra .ssy (stack inspect symbol) file type (written
by the compiler), and modifies the stack frames on the stack that they include an additional
word, which encodes the corresponding `.ssy` entry as well as the size of the stack frame
and whether it contains a return address to the previous stack frame. This information can be
used when printing a backtrace, to reduce the risk of false positive return addresses, as well
as to augment the backtrace with local variable information. As the stack frame format has
changed, the whole system needs to be recompiled.

As the printing of the backtrace is a constrained environment (both in respect to the available
stack and in potential heap memory pressure), backtrace output is not changed by default. You can
execute `ORStackInspect.OnTrap` and/or `ORStackInspect.OnAbort` to enable the functionality.
Regardless, you can embed calls to `ORStackInspect.Backtrace` to your code to print backtraces
programmatically. By default, `.ssy` files are ignored and therefore no local variables are
printed. You can call `ORStackInspect.Load YourModule` to load `YourModule.ssy`, or you can
call `ORStackInspect.LoadAll` to load all available `.ssy` files (for loaded modules).

During compilation, generation of `.ssy` files is also bound to the `/d` switch, just like
`.isy` files.


Installation
------------

- Apply [DoubleTrap](../DoubleTrap/README.md), [TrapBacktrace](../TrapBacktrace/README.md),
  [ZeroLocalVariables](../ZeroLocalVariables/README.md) and [ORInspect](../ORInspect/README.md),
  if not already applied.

- Push [`ORStackInspect.Mod.txt`](ORStackInspect.Mod.txt) and
  [`ORStackInspect.Tool.txt`](ORStackInspect.Tool.txt).

- Apply [`StackSymbols.patch`](StackSymbols.patch) to `ORB.Mod`, `ORG.Mod`, `ORP.Mod`,
  `System.Mod` and `Oberon.Mod`.

- Recompile the whole system, as the stack layout has changed:

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
      ORP.Compile ORStackInspect.Mod/s ~

- Restart the system.

- Recompile all modules that you want to inspect, with the /d switch.

- Open `ORStackInspect.Tool` and start inspecting.
