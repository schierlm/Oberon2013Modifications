OnScreenKeyboard - Little keyboard on the screen when no real keyboard is available

Description
-----------

Assume you want to run Oberon on a FPGA where you can attach a mouse or pointing
device, but no keyboard. It should still be possible to toy with the system, until
you find a way to add a keyboard.

In theory, no keyboard is needed, since you can always use interclicks to copy
individual letters from a text file. But there are places (e.g. Draw) where this
does not work, and there are some keys (e.g. F1 or Esc) that cannot be copy&pasted.

Also, maybe your pointing device is not able to do interclicks?

This solution uses a modified Text viewer that displays
[`OnScreenKeyboard.Text`](OnScreenKeyboard.Text.txt). On a left click, the clicked
letter will be inserted (by injecting it into `Input.Mod`) in lower case, on a
right click, it will be inserted in upper case. A middle click will insert the
lowercase letter prepended by a space. Clicking on an empty space will insert space,
tab or line feed, depending on the mouse button used.

Other keys are available as special keywords to click onto. The F1 keyword can be
dragged to the point where F1 should be injected.

For interclicks, there are special keywords too, that will affect the next "real"
click.


Installation
------------

- Apply [`InjectInput.patch`](InjectInput.patch) to `Input.Mod`.

- Push `OnScreenKeyboard.Mod` and `OnScreenKeyboard.Text`.

- Recompile `Input.Mod` and all dependencies (including the compiler):

      ORP.Compile Input.Mod/s Oberon.Mod/s ~
      ORP.Compile MenuViewers.Mod/s ~
      ORP.Compile TextFrames.Mod/s ~
      ORP.Compile System.Mod/s ~
      ORP.Compile Edit.Mod/s ~
      ORP.Compile ORS.Mod/s ORB.Mod/s ~
      ORP.Compile ORG.Mod/s ORP.Mod/s ~

- Compile the new module:

      ORP.Compile OnScreenKeyboard.Mod/s ~

- Restart the system.

- Run `OnScreenKeyboard.Show`.
