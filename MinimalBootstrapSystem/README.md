MinimalBootstrapSystem - Minimal disk image that can be used to bootstrap/compile the normal system

Description
-----------

As many other compilers/systems, Oberon is designed to be bootstrapped from an older
version of itself. But what parts of the system do you actually need (running in and
emulator) to still be able to recompile the system and eventually end up with a fully
functional system?

All input can be scrapped, since you can upload files via PCLink. When uploading `.Mod`
files, they can automatically be compiled. In theory, also no output is required, but
it would make error search too cumbersome. And we already have a solution of
[creating really tiny fonts](../MinimalFonts/README.md). As there is no input,
a Log viewer is all we need. However, it would not scroll, and scrolling is, in fact,
overkill. Let's just make two columns of text, and when one column is full, clear
and continue in the other column (similar to how ancient Tektronix terminals behaved).

For convenience, the inner core is unchanged, so you can in fact update every module by
just uploading (and automatically compiling) it.


Building the image
------------------

- You will need `PCLinkCompile.Mod` as PCLink alternative, as well as
  `BootstrapSystem.Mod` as `System.Mod` alternative.

- Apply [`BootstrapOberon.patch`](BootstrapOberon.patch) to `Oberon.Mod`.

- You may also apply [`ShrinkDisplayAndTexts.patch`](ShrinkDisplayAndTexts.patch)
  to remove unneeded parts from `Display.Mod` and `Texts.Mod`.

- Use one of the minimal `Fonts.Mod` files from [MinimalFonts](../MinimalFonts/README.md).

- Recompile the modules in this order:

      ORP.Compile Display.Mod/s  ~
      ORP.Compile Fonts.Mod/s Texts.Mod/s ~
      ORP.Compile Oberon.Mod/s ~
      ORP.Compile PCLinkCompile.Mod/s ~
      ORP.Compile BootstrapSystem.Mod/s ~
      ORP.Compile ORS.Mod/s ORB.Mod/s ~
      ORP.Compile ORG.Mod/s ORP.Mod/s ~

- Do not restart the system any more, since otherwise you will end up in the minimal
  bootstrap system. Instead remove all unneccesary files and shrink the image.

- You will need to keep these files:

      Display.rsc Fonts.rsc Texts.rsc Oberon.rsc  BootstrapSystem.rsc
      PCLinkCompile.rsc
      ORS.rsc ORB.rsc ORG.rsc ORP.rsc ~

- In case you want to be able to replace `Fonts.Mod` or the compiler without the rest
  of the system, or in case you want to avoid recompiling the inner core (accidentally
  adding incompatibilities), you may add some symbol files as well:

      Kernel.smb FileDir.smb Files.smb Modules.smb Texts.smb Oberon.smb

- For convenience, a [compressed pre-built minimal bootstrap image is available](MinimalBootstrapImage.dsk.xz).

Restoring the full system
-------------------------

- Upload fonts and tools

- Upload (and compile) Fonts.Mod

- Restart the system to get better fonts

- Upload the whole system:

      Input.Mod Display.Mod Viewers.Mod Fonts.Mod Texts.Mod Oberon.Mod
      MenuViewers.Mod TextFrames.Mod System.Mod Edit.Mod
      ORS.Mod ORB.Mod ORG.Mod ORP.Mod

- Upload PCLink1.Mod so you will be able to upload the remaining files and modules.

- Restart the system

