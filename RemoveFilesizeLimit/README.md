RemoveFilesizeLimit - Remove the 3MB file size limit

Description
-----------

The oberon filesystem limits the file size to 3131 sectors of each 1KB, so slighty
more than 3 MB. For most files, this is sufficient, but occasionally (e.g. when
building Oberon disk images within Oberon or when splitting large Oberon text files
into parts), a tiny fractions of the files need to be larger.

Therefore, I did not try to do any more sophisticated size limit expansion, but
instead opted to use this slight modification of the filesystem structure:
Originally, each file has 64 sector table entries and 12 extended entries (which
each contain 256 sector entries). The modification reduces the extended entries
to 11, and have the originally 12th entry point to a "linked list" of sector
entries instead: This linked entry sector consists of 255 normal sector table
entries, and one last linked entry which points to another such sector. This way,
files can grow arbitrarily large (up to the filesystem size limit of 64 MB), and
filesystems that do not include files larger than 2880 sectors (2.88 MB) are 100%
compatible between these two formats.

The filesystem size limit of 64 MB is caused by a sector bitmap which is stored
in RAM (in the Kernel module). The easiest way to overcome this limitation (without
requiring an on-disk bitmap or increasing the RAM usage) is to notice that a sector
that has been used will not be freed until the next reboot. Therefore it is
sufficient to keep a "sliding window" of the sector bitmap in the RAM; once all
sectors in this sliding window are used, rescan the filesystem to generate the next
window. For performance reasons, and to enable features like the Defragger, the
last used sector number is also kept available all the time, even when it is outside
the current sliding window.


Installation
------------

- Apply [`LinkedExtensionTable.patch`](LinkedExtensionTable.patch) to `FileDir.Mod`
  and `Files.Mod` (and optionally `DefragFiles.Mod` if you want to use the defragger).

- Optionally apply [`SlidingSectorBitmap.patch`](SlidingSectorBitmap.patch) to `Kernel.Mod`,
  `FileDir.Mod` and `Files.Mod` (and optionally `DefragFiles.Mod` and `Defragger.Mod` if you
  want to use the defragger).

- Push the new modules.

- Recompile the inner core and rebuild the whole system (including the compiler):

      ORP.Compile Kernel.Mod/s FileDir.Mod/s Files.Mod/s Modules.Mod/s ~
      ORL.Link Modules ~
      ORL.Load Modules.bin ~

      ORP.Compile Input.Mod/s Display.Mod/s Viewers.Mod/s ~
      ORP.Compile Fonts.Mod/s Texts.Mod/s ~
      ORP.Compile Oberon.Mod/s ~
      ORP.Compile MenuViewers.Mod/s ~
      ORP.Compile TextFrames.Mod/s ~
      ORP.Compile System.Mod/s ~
      ORP.Compile Edit.Mod/s ~
      ORP.Compile ORS.Mod/s ORB.Mod/s ~
      ORP.Compile ORG.Mod/s ORP.Mod/s ~

- Restart the system.
