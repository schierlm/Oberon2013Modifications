CursorKeys - Support cursor keys in TextFrames and GraphicFrames

Description
-----------

In Project Oberon, the expectation is that every cursor positioning is done
by the mouse. In practice, it is nice to be able to correct it using cursor
keys.

This modification adds cursor key support to both TextFrames and
GraphicFrames. It also adds support for the Delete key to TextFrames.

In GraphicFrames, all selected objects as well as all crosshair marks can be
moved simultaneously by pressing the cursor keys. The distance depends on
whether ticks are enabled or not.

Similar to other Oberon variants, this modification uses ASCII codes 11H to
14H for the cursor keys (left, right, up, down).

Installation
------------

- Apply [`CursorKeys.patch`](CursorKeys.patch) to `Input.Mod`,
  `TextFrames.Mod` and `GraphicFrames.Mod`.

- Recompile the changed modules:

      ORP.Compile Input.Mod TextFrames.Mod GraphicFrames.Mod ~

- Restart your system
