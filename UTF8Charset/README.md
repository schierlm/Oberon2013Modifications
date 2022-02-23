UTF8Charset - Display UTF-8 characters in a Text viewer

Description
-----------

Project Oberon is designed to be US-ASCII only - at many places, characters larger
than 127 are discarded or skipped.

This modification adds UTF-8 support to Texts and text viewers. Other places
(like file names) still stay US-ASCII only.

As the Font format only supports 16-bit codepoints, only the Basic Multilingual
Plane is supported. Also, Right-to-left characters, ligatures or other combining
characters are not supported.

Still, after this modification, Cyrillic, Greek or other similar scripts
are no problem.

The original `Fonts.Mod` always loads all glyphs. As Unicode fonts can grow quite
big and often only very few glyph ranges are needed, the modified `Fonts.Mod` loads
glyphs in ranges of 64 character. A two-way indirect lookup table (16\*64\*64 entries)
is used to lookup loaded glyphs.

Glyphs that do not exist in a font are rendered as fallback glyphs, containing 4 tiny
hex digits representing the codepoint.

While `Input.Mod` can support unicode codepoints now, the default US keyboard layout
does not make use of them. Creating Unicode codepoints (if no Clipboard is available)
therefore has to be done by calling `Edit.InsertUnicode 20ACH` or similar.

Installation
------------

- Apply [`UTF8Charset.patch`].

- Recompile the changed modules and their dependencies (including the compiler):

      ORP.Compile Input.Mod/s ~
      ORP.Compile Fonts.Mod/s Texts.Mod/s ~
      ORP.Compile Oberon.Mod/s ~
      ORP.Compile MenuViewers.Mod/s ~
      ORP.Compile TextFrames.Mod/s ~
      ORP.Compile System.Mod/s ~
      ORP.Compile Edit.Mod/s ~
      ORP.Compile ORS.Mod/s ORB.Mod/s ~
      ORP.Compile ORG.Mod/s ORP.Mod/s ~

- Restart the system.
