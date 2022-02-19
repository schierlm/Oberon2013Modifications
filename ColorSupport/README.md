ColorSupport - Support both monochrome and 16-color modes

Description
-----------

**NOTE**: Unlike other modifications, this modification is not standalone. It requires that
you applied the [HardwareEnumerator](../HardwareEnumerator/README.md) modification,
before this modification.

With the advent of the hardware enumerator, it may become more common for boards
and emulators to both support monochrome and color modes at the same time.

This modification introduces a new "switching" `Display.Mod` which can dynamically
choose between `DisplayM` and `DisplayC` modules. Each of the modules features an
identical symbol file, so in case only one of the modes is supported, the files can
be interchanged.

In case the color module detects that the current mode is monochrome (or vice versa),
it sets `Span` to 0 and `Width` and `Height` to the first supported mode of the
correct type. Extra logic in `Display.ReplConst` (which is the first command invoked
during startup) will detect this condition and switch to this mode, which will happen
only if the module is used standalone. The switching module will also use this condition
to decide which color depth to start with.

The color palette is expected to have black as color 0 and white as color 15 (or similar
high-contrast colors), as the modification will not use any other colors by default.

Installation
------------

- Apply [HardwareEnumerator](../HardwareEnumerator/README.md), if not already applied.

- Rename `Display.Mod` to `DisplayM.Mod`.

- Apply [`ColorSupport.patch`](ColorSupport.patch) to `DisplayM.Mod`, `Texts.Mod`
  and `System.Mod`.

- In case you want to use the draw addons, apply [`DrawAddons.patch`](DrawAddons.patch)
  to `DisplayGrab.Mod`.

- In case you want to use the rescue system, apply [`RescueSystem.patch`](RescueSystem.patch)
  to `System.Tool.RS`.

- Push `Display.Switch.Mod` as `Display.Mod`, as well as `DisplayC.Mod`.

- Recompile all three `Display.Mod`, `Texts.Mod` and all dependencies (including the compiler):

      ORP.Compile DisplayC.Mod/s DisplayM.Mod/s Display.Mod/s ~
      ORP.Compile Viewers.Mod/s Texts.Mod/s Oberon.Mod/s ~
      ORP.Compile MenuViewers.Mod/s TextFrames.Mod/s ~
      ORP.Compile System.Mod/s Edit.Mod/s ~
      ORP.Compile ORS.Mod/s ORB.Mod/s ~
      ORP.Compile ORG.Mod/s ORP.Mod/s ~

- Restart the system.
