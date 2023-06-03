UnicodeFontIndex - Speed up partial loading of Unicode fonts

Description
-----------

**NOTE**: Unlike other modifications, this modification is not standalone. It requires that
you applied the [UTF8Charset](../UTF8Charset/README.md) or
[UTF8CharsetLite](../UTF8CharsetLite/README.md) modification, before this modification.

As Unicode fonts can grow quite big and often only very few glyph ranges are needed, the
`Fonts.Mod` from the [UTF8Charset](../UTF8Charset/README.md) modification loads glyphs in
ranges of 64 character. However, on every load, the whole runs table and a large chunk of
the boxes table need to be parsed to find the required offsets into the glyphs table. This
modification introduces a Unicode Font Index file `*.Scn.uFi` which contains precalculated
offsets for each range present in the file, indexed by a two-way indirect lookup table
similar to the one used in memory when loading the font. `UnicodeFontIndex.Build` can be
used to build such index files for Unicode fonts.


Index File Format
-----------------

The file consists of a 20 byte header followed by 512-byte pages. The pages are 1-based,
i. e. the start offset for page number `i` is `i * 512 - 492`.

The maximum size of a file (for a font that covers *all* of Unicode) is 16 pages (about
8 KiB). Page numbers in the file can therefore be encoded as a single byte.

The header consists of a magic value `01694675H` followed by page numbers for the 16 lookup
tables. If a lookup table is not present, the page number is zero.

Each lookup table consists of one page and stores for each of the 64 glyph ranges:
- The number of runs to skip when loading the range (i.e. non-overlapping runs before the
  first overlapping run) [2 bytes]
- The number of boxes to skip when loading the range [2 bytes]
- Offset of the first glyph covered in this range [4 bytes]

In case a range does not contain any glyphs, the values are all -1.

When building the index, pages are allocated and everything except the glyph offsets are filled
while parsing the runs. Then the glyph offsets will be dynamically updated while parsing the boxes.


Installation
------------

- Apply [`UnicodeFontIndex.patch`](UnicodeFontIndex.patch) to `Fonts.Mod`
  (or `FontsU.Mod` in case of `UTF8CharsetLite` modification)

- Recompile the changed modules and their dependencies (including the compiler).
  In case of `Fonts.Mod`:

      ORP.Compile Fonts.Mod/s Texts.Mod/s ~
      ORP.Compile Oberon.Mod/s ~
      ORP.Compile MenuViewers.Mod/s ~
      ORP.Compile TextFrames.Mod/s ~
      ORP.Compile System.Mod/s ~
      ORP.Compile Edit.Mod/s ~
      ORP.Compile ORS.Mod/s ORB.Mod/s ~
      ORP.Compile ORG.Mod/s ORP.Mod/s ~

  In case of `FontsU.Mod`:

      ORP.Compile FontsU.Mod/s TextFramesU.Mod/s EditU.Mod/s ~

- Compile the index builder

      ORP.Compile UnicodeFontIndex.Mod/s ~

- Build indexes for your fonts

      UnicodeFontIndex.Build Oberon10.Scn.Fnt ~

- Restart the system.
