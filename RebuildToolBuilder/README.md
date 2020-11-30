RebuildToolBuilder - Build a list of modules that need to be rebuilt

Description
-----------

When patching low-level parts of the system, it is too easy to forget recompiling
a dependent module. Or you rebuild them in the wrong order and some of them will
not work due to bad import keys.

In case there are any missing modules (`.rsc` but not `.Mod`) or uncompiled modules
(`.Mod` but not `.rsc`), these are listed. Only if they are corrected (by compiling
the modules or deleting the `.rsc` files), the module list will be built.

As other modifications introduce other switches than `/s`, it is possible to pass
arbitrary switches to the RebuildToolBuilder.Build` command and they will be
reproduced on every command line.

Each entry of the list consists of a compile command, followed by a flag character
how important it is to rebuild the module. Note that this information is only reliable
if your Oberon system has a reliable real-time clock. If not, you can only start from
the top and recompile everything.

- `-`: Module (probably) does not need to be recompiled (timestamp is older)
- `?`: Unsure (there are two timestamps that are same)
- `!`: Module needs to be recompiled as its timestamp is newer
- `*`: Module needs to be recompiled as one of its dependencies needs to be recompiled
  or its timestamp is newer

Installation
------------

- Push the new module

- Compile the new module:

      ORP.Compile RebuildToolBuilder.Mod/s ~

- Run `RebuildToolBuilder.Build`.
