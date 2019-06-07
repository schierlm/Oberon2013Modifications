ConvertEOL - Convert line terminators when loading text files as ASCII

Description
-----------

When transferring ASCII files to the Oberon system and the transfer program
or emulator does not provide automatic EOL conversion, you have to manually
convert LF or CRLF to CR, or you end up with very long lines in the Oberon
system.

In Oberon there can be loaded two different types of text files: The
Oberon-native format which may include formatted text, and ASCII text which
will be converted upon loading.

This modification changes the loader of ASCII files so that different line
endings will be converted to CR. Writing files and loading Oberon-native files
is not changed and will produce/expect CR as before.

(This is different to the modification described in
[this technote](https://github.com/io-core/technotes/blob/master/technote001.md),
where the line endings in Oberon-native files are also changed.
To produce ASCII text in (by default) CRLF line ending, `Tools.Convert` has
to be used, just like without this modification.)

The simplest implemetation requires reordering the exported methods in
`Texts.Mod`, which unfortunately requires recompilation of most of the
Oberon system. Therefore, for convenience, a second patch is provided
which will use a procedure variable to avoid changing the symbol file
of `Texts.Mod`.


Installation
------------

- Apply [`ConvertEOL.patch`](ConvertEOL.patch) to `Texts.Mod`.

- If you do not want to recompile your system, also apply [`ConvertEOL.SameSymbolFile.patch`] to `Texts.Mod`.

- In case you applied both patches, recompile `Texts.Mod`:

      ORP.Compile Texts.Mod ~

- In case you did not apply the first patch, recompile `Texts.Mod` and the rest of the system, allowing new symbol files

      ORP.Compile Texts.Mod/s Oberon.Mod/s ~
      ORP.Compile MenuViewers.Mod/s ~
      ORP.Compile TextFrames.Mod/s ~
      ORP.Compile System.Mod/s ~
      ORP.Compile Edit.Mod/s ~
      ORP.Compile ORS.Mod/s ORB.Mod/s ~
      ORP.Compile ORG.Mod/s ORP.Mod/s ~

- Restart your system

- You can test with `Example.Text` if all kinds of EOLs are correctly handled.
