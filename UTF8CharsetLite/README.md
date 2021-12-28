UTF8Charset - UTF-8 support, limited to special Unicode text viewers

Description
-----------

Project Oberon is designed to be US-ASCII only - at many places, characters larger
than 127 are discarded or skipped. The [UTF8Charset](../UTF8Charset/README.md)
modification changes this, but requires drastic changes in both font and text
management. Therefore, other modules often need to be adjusted to work in an UTF-8
capable Oberon.

On the other hand, in most cases, Unicode display support is not required, only a
very few files actually have Unicode characters inside them. And since the Input
driver does not produce those Unicode characters anyway (if you use the default
Input module that implements a QUERTY keyboard), it is often overkill to have
Unicode support in every text viewer.

Instead, this modification introduces a TextFramesU module (with the accompanied
EditU toolbox module), so you can view individual files in Unicode viewers on an
otherwise almost unchanged system: The only module that needs patching (without
changing the symbol file) is `Fonts.Mod`, as fonts will first be loaded by the
`Fonts` module, and then later again by the `FontsU` module in case they appear
in Unicode viewers. Therefore, Unicode fonts may not TRAP the `Fonts` module.
However, as the module by default only uses 8-bit glyph indices, and also tries
to load all "boxes and runs" into memory before examining the glyphs, loading
large Unicode fonts often results in array index TRAPs. Therefore, the handling
of 16-bit glyph indices needs to be introduced, in addition to skipping "boxes
and runs" of glyphs outside the US-ASCII range.


Installation
------------

- Create a temporary copy of `Fonts.Mod` and `TextFrames.Mod`.

- Apply [`UTF8Charset.patch`](../UTF8Charset/UTF8Charset.patch) from the
  [UTF8Charset](../UTF8Charset/README.md) modification to these two files
  (discard all changes to other files).

- Rename these two files to `FontsU.Mod` and `TextFramesU.Mod`.

- Apply [`UTF8CharsetLite.patch`](UTF8CharsetLite.patch) to `FontsU.Mod`,
  `TextFramesU.Mod` and (the original) `Fonts.Mod`.

- Push the new modules.

- Recompile the changed `Fonts` module and the new modules:

      ORP.Compile Fonts.Mod ~
      ORP.Compile FontsU.Mod/s TextsU.Mod/s ~
      ORP.Compile TextFramesU.Mod/s EditU.Mod/s ~

- Restart the system.

- Use the commands in `EditU.Tool`.
