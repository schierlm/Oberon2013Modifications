CrossCompiler - Compile a second set of modules without affecting the current system

Description
-----------

[I know that using the term CrossCompiler for this modification may be a bit of an
overstatement, but it is catchy and covers **one** part of cross compilation.]

Sometimes you want to experiment with changes to the Oberon core files (when you
build modifications like me, rather often than sometimes). When compiling the new
version of modules on a live system, and the last module contains a compile error,
you have to make sure that you fix it before restarting the system, since otherwise
your system and/or your compiler may end up broken.

This modification introduces a `/x` switch to the compiler (similar to the `/s` switch)
which will redirect the output files "somewhere else" - in particular, object and symbol
files are written as `.rsc.X` and `.smb.X`, respectively. That way, broken compilation
can not break your build, and you can (if you want to) copy the modified files out of
the RISC system, rename them, and build a new system from them.

As the option handling was overhauled in the [InspectSymbols](../ORInspect/InspectSymbols.patch)
patch of the [ORInspect](../ORInspect/README.md) modification, this modification depends on
the ORInspect modification.

Installation
------------

- Apply [ORInspect](../ORInspect/README.md), if not already applied.

- Apply [`CrossCompiler.patch`](CrossCompiler.patch) to `ORB.Mod`, `ORG.Mod`, and `ORP.Mod`.

- Recompile the compiler:

      ORP.Compile ORB.Mod/s ~
      ORP.Compile ORG.Mod/s ORP.Mod/s ~

- Restart the system.

- You may now use the /x switch for cross compiling.
