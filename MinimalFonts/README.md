MinimalFonts - Minimal Fonts modules with a single font embedded to save space and avoid filesystem access

Description
-----------

It bugged me several times that to successfully boot an Oberon system, it is required to load
a font file from the filesystem. Having a `System.Tool` is optional and the boot modules can
also be loaded from serial line, but without a font file, you won't be able to read anything
or interact with the system. In most cases, having a single font, `Oberon10.Scn.Fnt` is sufficient
for using the system.

Therefore, you can find here two implementations of a minimal Fonts module which embed their fonts.

The first one embeds the original `Oberon10.Scn.Fnt` patterns (for TAB as well as characters 32-126),
therefore providing the same user experience as the default, as long as only valid ASCII characters
and only this one font is used.

The second one embeds an ugly, generated font, which is a lot smaller, and might be useful in scenarios
where you want to boot a system with very constrained memory (In the generated font, lowercase letters
look like uppercase letters shifted down by one pixel, but compared to the file size, the font is
[surprisingly easy to read](minimal-font.png)). This font uses only 16 bits for each glyph;
15 of them provide a 3x5 matrix, and the remaining one is used to shift the glyph down by one pixel.

Both modules only support one font, so regardless which font is requested, it will always return the same
font. Both modules do not change the symbol file, so you can easily update the fonts module without having
to recompile any dependent modules.

Also, a `FontsDumper` utility module is provided which can be used to dump the patterns of a font to System.Log,
so you can copy them from there into the first module (if you want to use a different default font).

File sizes
----------

- Original `Fonts.rsc`: 2649 bytes
- `Oberon10.Scn.Fnt`: 2284 bytes
- Both of these files: 4933 bytes

- Embedded `Fonts.rsc`: 2229 bytes
- Minimal `Fonts.rsc`: 1289 bytes



Installation
------------

- Push `Fonts.Embedded.Mod` or `Fonts.Minimal.Mod` to your Oberon system.

      ORP.Compile Fonts.Embedded.Mod ~
      ORP.Compile Fonts.Minimal.Mod ~

- Restart your system