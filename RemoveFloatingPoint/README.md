RemoveFloatingPoint - Build an Oberon system without Floating Point support

Description
-----------

While floating point is certainly important in general-purpose computers, it is mostly
unneccessary in some embedded systems. Also, floating point support needs considerable
space on a FPGA, therefore you may want to remove it.

Turns out, there are only very few modules in the Project Oberon outer core that actually
require floating point - `Files.Mod` to read and write REAL values, `Texts.Mod` to read
and parse them, and of course the compiler.

But even when you remove floating point from the compiler, it is straightforward to later
compile a compiler with floating point support on the compiler that does not have it
(probably because that is the way how floating point support was added to the compiler
in the first place).


Removing Floating Point
-----------------------

- Apply [`RealityLost.patch`](RealityLost.patch) to `Files.Mod`, `Texts.Mod` and
  the compiler.

- Recompile `Files.Mod` and rebuild the whole system (including the compiler):

      ORP.Compile Files.Mod/s Modules.Mod/s ~
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

- Restart the system.

Adding back Floating Point
--------------------------

- Revert the patch from above

- Apply [`RealityRegained.patch`](RealityRegained.patch) to the compiler.

- Recompile the compiler first:

      ORP.Compile ORS.Mod/s ORB.Mod/s ~
      ORP.Compile ORG.Mod/s ORP.Mod/s ~

- Restart the system

- Recompile `Files.Mod` and rebuild the whole system (including the compiler):

      ORP.Compile Files.Mod/s Modules.Mod/s ~
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

- Restart the system.
