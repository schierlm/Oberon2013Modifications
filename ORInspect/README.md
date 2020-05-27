ORInspect - Inspect global module variables and heap pointers

Description
-----------

Debugging capabilities of Project Oberon are limited. You can output things to System.Log
or you can get raw memory dumps. This is far from what you can expect from other debuggers.

As a very minimal way of symbolic variable inspection, this modification adds an extra
.isy (inspect symbol) file type (written by the compiler) and two commands:

`ORInspect.Module` will print all global variables of a module. `ORInspect.HeapAddress`
prints all fields of the (actual) record pointing to a given address (determined from
the type descriptor) Arrays are flattened, and pointers are printed as
`ORInspect.HeapAddress` command, so you can dig deeper if desired.

Due to the flattened arrays, `.isy` files can grow quite large, so you will only want
to generate them if you want to use them. Therefore, a new compiler switch `/d` was added
to control whether debugging info (`.isy` files) should be generated.

On the other hand, flattened arrays and records have the advantage that every `ORInspect`
command needs to load at most one `.isy` file. Which brings another disadvantage: In case
a variable or record field (possibly extension) is from a type exported by another module,
but the field itself is not exported, the field name is not included in the (normal) symbol
file and therefore cannot be added to the inspect symbol file. If this bothers you, a
secondary patch is available which will change the symbol file format to include such fields;
in the same format as exported fields, but prefixing the name with `-`. Pointer types
will get erased, as the pointed type may not be exported, and they are not needed since
`ORInspect.HeapAddress` will look up the actual type from the type descriptor anyway.

When following heap address references, it can happen that the objects get garbage collected
before you have a chance to inspect them. To minimize this risk, ORInspect can keep references
to the last up to 256 objects that it printed references to. To use this, call
`ORInspect.KeepHeapAlive` and pass the number of objects you want to keep alive as a parameter.

Installation
------------

- Push [`ORInspect.Mod.txt`](ORInspect.Mod.txt) and [`ORInspect.Tool.txt`](ORInspect.Tool.txt)

- Apply [`InspectSymbols.patch`](InspectSymbols.patch) to `ORP.Mod`, and `ORB.Mod`.

- Optionally apply [`MoreSymbole.patch`](MoreSymbole.patch) to `ORB.Mod`.

- In case you only applied the first patch, it is sufficient to recompile the compiler:

      ORP.Compile ORB.Mod/s ORInspect.Mod/s ~
      ORP.Compile ORG.Mod/s ORP.Mod/s ~

- In case you applied both patches, recompile the whole system, as the symbol file format changed:

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
      ORP.Compile ORInspect.Mod/s ~

- Restart the system.

- Recompile all modules that you want to inspect, with the /d switch.

- Open `ORInspect.Tool` and start inspecting.

