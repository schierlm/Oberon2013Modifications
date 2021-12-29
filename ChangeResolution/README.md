ChangeResolution - Dynamically change the display resolution if the driver supports it

Description
-----------

Project Oberon assumes a monochrome display with fixed resolution. Various progress has been made
to provide multiple resolutions (or even multiple color depths). However, at the moment the resolution
needs to be chosen at boot time and cannot be changed.

This modification modifies `Display.Mod` to provide a `SetSize` procedure that receives the desired
screen size and returns whether switching was successful (the default implementation always returns `FALSE`).
A command `System.SetScreenSize` will read the desired resolution, try to set it in the display driver, and
then inform the system by calling `Oberon.UpdateScreenSize`, which will in turn inform `Input` (to update
the mouse bounds) and `Viewers` (to resize all open viewers and tracks).

Installation
------------

- Apply [`ChangeResolution.patch`](ChangeResolution.patch) to `Display.Mod`, `Viewers.Mod`,
  `Oberon.Mod` and `System.Mod`.

- Probably use a different `Display´ driver that actually supports multiple resolutions.

- Recompile `Display.Mod`, `Viewers.Mod` and all dependencies (including the compiler):

      ORP.Compile Display.Mod/s Viewers.Mod/s ~
      ORP.Compile Oberon.Mod/s ~
      ORP.Compile MenuViewers.Mod/s ~
      ORP.Compile TextFrames.Mod/s ~
      ORP.Compile System.Mod/s ~
      ORP.Compile Edit.Mod/s ~
      ORP.Compile ORS.Mod/s ORB.Mod/s ~
      ORP.Compile ORG.Mod/s ORP.Mod/s ~

- Restart the system.
