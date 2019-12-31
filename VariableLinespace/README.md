VariableLinespace - Support lines of different height in the same Text viewer

Description
-----------

One "step backward" in Project Oberon (compared to other Oberon systems
available) is that it does not support variable line heights - every line
in a text viewer is the height of the default font. Using smaller fonts does
not save space, and using larger fonts results in overlapping lines, forcing
you to tweak the default font size every now and then (or avoid using different
font sizes completely).

This modification changes `TextFrames.Mod` so that it supports different
text heights again - the height of a line is determined from its largest font.

Installation
------------

- Apply [`VariableLineSpace.patch`](VariableLineSpace.patch) to `TextFrames.Mod`.

- Recompile `TextFrames.Mod`:

      ORP.Compile TextFrames.Mod ~

- Restart your system
