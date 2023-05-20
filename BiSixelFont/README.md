BiSixelFont - Display small images in Text frames

Description
-----------

On old terminals, there used to be a Sixel font which was six pixels high and
could display small pixel graphics. As the default line height in Oberon is 12
pixels, we use a BiSixel font instead. This font includes the following characters:

- Spaces that are one and twelve pixels wide (SPC and TAB)
- Zero-width characters that fill every combination of the top 4,
  middle 4 or bottom 4 pixels (a total of 15*3: 0-9 A-Z a-i)
- Copies of the middle 4 combinations as one pixel wide variant
  (A total of 15, j-x)
- Filled blocks that are one and twelve pixels wide (y and z)

These characters can be used to display any `.Pict` file that is a multiple
of 12 pixels high in a Text frame (or the Log viewer).

This modification contains the `BiSixelFontBuilder` module (which is used to
dynamically build the font and can be deleted after building), and the
`BiSixelConerter` module which is used  convert black/white and color pictures
to BiSixels. Black and white pictures show as white (color 1) on transparent
(color 0) and can be recolored by using the `ChangeColor` command. For color
pictures, the user can choose which color (if any) should be transparent.

Installation
------------

- Push the new modules and tools

- Compile the new modules:

      ORP.Compile BiSixelConverter.Mod/s BiSixelFontBuilder.Mod/s ~

- Use the commands in [`BiSixelFont.Tool`](BiSixelFont.Tool.txt)
