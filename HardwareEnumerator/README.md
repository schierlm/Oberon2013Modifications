HardwareEnumerator - Make disk images hardware independent by enumerating hardware at startup

Description
-----------

**NOTE**: Unlike other modifications, this modification is not standalone. It requires that
you applied the [RemoveFilesizeLimit](../RemoveFilesizeLimit/README.md),
[DefragmentFreeSpace](../DefragmentFreeSpace/README.md), [RealTimeClock](../RealTimeClock/README.md),
[WeakReferences](../WeakReferences/README.md) and [ChangeResolution](../ChangeResolution/README.md)
modifications, and parts of the [FontConversion](../FontConversion/README.md) and
[KernelDebugger](../KernelDebugger/README.md) modification, before this modification.

While Project Oberon was originally designed to run on a single board, there are
now multiple boards (and emulators) with varying capabilities available. Not all
of them provide the same hardware support. As a consequence, when moving a disk
(image) from one system to another one, often parts of the system need to be
recompiled to take advantage of the changed hardware configuration.

Therefore, [the hardware enumerator specification](https://github.com/schierlm/OberonEmulator/blob/master/hardware-enumerator.md)
tries to provide an interface that can be called by the software
to obtain insight about the installed hardware.

This modification provides a basic implementation for the software side of the
hardware enumerator. It will support different input and video configuration
(including dynamic mode switching), host FS support and power management.
However, it does *not* provide color support. It also does not try to introduce
any abstractions; all the decisions have been added into the original modules,
making them not necessarily easier to read.

This modification also provides patches for other modifications, where it makes
sense.

Last but not least, a `HardwareDetect` modules is included, which prints details
about CPU, memory and display configuration, before dumping all hardware enumerator
data.

Installation
------------

- Apply [RemoveFilesizeLimit](../RemoveFilesizeLimit/README.md), [DefragmentFreeSpace](../DefragmentFreeSpace/README.md),
  [RealTimeClock](../RealTimeClock/README.md), [WeakReferences](../WeakReferences/README.md)
  and [ChangeResolution](../ChangeResolution/README.md), if not already applied.

- Apply [`RemoveGlyphWidthLimit.patch`](../FontConversion/RemoveGlyphWidthLimit.patch) from the **FontConversion**
  modification to `Display.Mod` (if not already applied).

- Apply [`RS232.patch`](../KernelDebugger/RS232.patch) from the **KernelDebugger**
  modification to `RS232.Mod` (if not already applied).

- Apply [`HardwareEnumerator.patch`](HardwareEnumerator.patch) to `Kernel.Mod`,
  `FileDir.Mod`, `Files.Mod`, `Input.Mod`, `Display.Mod`, `Oberon.Mod`, `RS232.Mod`,
  `SCC.Mod` and `System.Mod`.

- Push [`HardwareDetect.Mod.txt`](HardwareDetect.Mod.txt).

- In case you want to use the keyboard tester, or rescue system, inner emulator, or
  draw addons, there are patches for them as well.

- Recompile `Kernel.Mod` and rebuild the whole system (including the compiler):

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

- Compile the new module:

      ORP.Compile HardwareDetect.Mod/s ~

- Restart the system.
