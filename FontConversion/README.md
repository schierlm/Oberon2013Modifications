FontConversion - Conversions to and between Oberon .Scn.Fnt files

Description
-----------

This modification contains five unrelated changes about converting fonts, which
work well together.

### Mod1: Handle glyphs wider than 32 pixels

By default, fonts with glyphs wider than 32 pixels cannot be displayed. This is due
to a limitation in `Display.CopyPattern` which cannot copy wider patterns. If you want
to use larger fonts, this modification patches `Display.Mod` to support wider patterns
(unlimited width).

### Mod2: Create larger fonts from small ones by using Pixel-art scaling algorithms

The default fonts available with Project Oberon are rather small. There are
[Pixel-art_scaling_algorithms](https://en.wikipedia.org/wiki/Pixel-art_scaling_algorithms)
which are optimized to scale images with few (or only 2) colors, without
introducing more colors. These algorithms can be used to produce larger fonts
from smaller ones.

### Mod3: Convert PCF fonts to Oberon fonts

[PCF fonts](https://en.wikipedia.org/wiki/Portable_Compiled_Format) were originally
designed for the X Window System, and therefore lots of pixel fonts (monospaced
and proportional ones) are available in this format.

There is support for directly using PCF fonts inside Oberon in
[Integrated Oberon](https://github.com/io-core/Edit/blob/795889b215dd831f44369f0a6edc0f8ec6caf05c/Fonts.Mod),
but this approach has the disadvantage that all the overhead of converting the font
has to happen on every load. Also, this implementation does not try to strip
blank borders from the fonts, thus needing more memory than needed.

Last but not least there are several forms PCF fonts can be encoded (different
bit and byte orders) and while Integrated Oberon only supports one of them,
this modification tries to support all the ones supported by bdftopcf tool, as
long as the scanline unit is 1 (or bit and byte order correspond). Supporting
different scanline units would complicate the implementation, and I have not found
any fonts in real life that use this obscure feature. Yet, if there are any, they
can be converted to using a scanline unit of 1 using existing tools.

The character set of the fonts should be either Unicode or Latin-1, otherwise,
the glyph order will be unexpected. As some fonts contain lots of glyphs, yet
Project Oberon by default only uses ASCII, there is a `ConvertASCIIOnly` command
which stops after codepoint 127.

### Mod4: Optimize font size (mostly relevant for PCF fonts) by stripping blank borders

My implementation for converting PCF fonts to Oberon fonts also does not strip
blank borders. Adding them into the single pass would have made the code
more complicated. Also, stripping blank borders is not only required for PCF fonts
but also if you use fonts converted from other formats by other tools. Therefore,
I moved the stripping of blank borders to a separate module. It can make font files
smaller (requiring less RAM) without changing the appearance. Obviously, if the
blank borders are already stripped (like with the Fonts that come with Project Oberon),
nothing is gained.

### Mod5: Extract font subsets

When converting PCF fonts for an Oberon system that has been patched for Unicode
support, you may want to convert more than ASCII only. Yet, some fonts (e.g. Unifont)
contain thousands of glyphs you may not want to use. Therefore, `FontSubsetBuilder` can
take a font and a list of Unicode ranges, and produce a font that only covers the
given subset by removing all other glyphs (and metadata) from the font.


Installation
------------

- For Mod1: Apply [`RemoveGlyphWidthLimit.patch`](RemoveGlyphWidthLimit.patch) to `Display.Mod`.

- For Mod2: Push `GrowFont.Mod`.

- For Mod3: Push `ConvertPCFFont.Mod`.

- For Mod4: Push `OptimizeFont.Mod`.

- For Mod5: Push `FontSubsetBuilder.Mod`.

- For any Mod except Mod1: Push `FontConversion.Tool`.


- Recompile/Compile the pushed modules:

      ORP.Compile Display.Mod ~
      ORP.Compile GrowFont.Mod/s ~
      ORP.Compile ConvertPCFFont.Mod/s ~
      ORP.Compile OptimizeFont.Mod/s ~
      ORP.Compile FontSubsetBuilder.Mod/s ~

- For Mod1: Restart the system.

- For any Mod except Mod1: Use the commands in [`FontConversion.Tool`](FontConversion.Tool.txt).
