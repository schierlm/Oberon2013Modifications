TrapBacktrace - Print a backtrace on TRAP and ABORT

Description
-----------

When a trap happens, Project Oberon prints the module name and the code position where
the trap originates. Often, these traps are inside system modules and caused by passing
an invalid value to some exported function. But without a backtrace, it is hard to find
where exactly the error happens.

In conditional trap jumps, the code position is encoded in some free bits of the
instruction itself, therefore no symbol files are required to print the position
in the trap output. However, function call jumps lack those free bits, so a different
way is needed to encode this information. This patch takes a simple approach and adds
a "jump never" instruction before such function call jumps, which is used to encode
the code position.

ABORT (pushing the reset button) have another problem: The stack register gets
overwritten by the boot loader, making it impossible to find a starting point for
the stack walk. This overwrite happens in the module header emitted by the compiler.
Therefore patch the compiler to emit an additional instruction to save the previous
stack pointer in Register 11, and patch the boot loader to use the value as stack
pointer before handing control back to the system.

Note that a patched bootloader is not required to get backtraces on TRAPs, only
to also get backtraces on ABORTs.


Installation
------------

- Apply [`TrapBacktrace.patch`](TrapBacktrace.patch) to `Edit.Mod`, `System.Mod`,
  `ORG.Mod` and `BootLoad.Mod`.

- Compile the patched modules:

    ORP.Compile Edit.Mod System.Mod ~
    ORP.Compile ORG.Mod ~
    ORP.Compile BootLoad.Mod ~

- Optionally update the boot loader on your FPGA.

- Restart the system.

- Recompile all modules that you want to have code positions in the backtrace
  (or all modules if you are unsure).
