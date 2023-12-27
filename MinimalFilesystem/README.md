MinimalFilesystem - Minimalistic filesystem code storing just a sequence of files with delete markers

Description
-----------

Oberon's filesystem is, by modern standards, quite minimalistic. But its B-Tree
structure as well as the direct and indirect pointers provide unneeded complexity
when building the filesystem from outside (e.g. when bootstrapping) . They also
make it hard to tinker with the filesystem structure on a running system.

This modification provides an even simpler filesystem, which results in very bad
performance and more disk activiaty, but is very easy to understand and modify.
Note that due to no B-Tree structure, the output of `System.Directory` is no longer
sorted. There are also paths provided to convert "normal" filesystems into minimal
ones and vice versa (as long as they are smaller than 1MB).

The general idea is that there is a root sector (sector 1024 as seen by the kernel;
the classic directory root is in sector 1 as seen by the kernel), which can start
with one of two file marks:

- `MinHdrMark = 9BA71D85H` designates this as a minimal filesystem where the first
  entry represents a file.
- `MinHleMark = 9BA71D84H` designates this as a minimal filesystem where the first
  entry represents a hole (a deleted file). Holes always have an empty file name.
- If neither mark is present, this is not a minimal filesystem (maybe check if there
  is a normal filesystem?)
- The file header structure is unchanged (except that files use `MinhdrMark` instead
  of `HeaderMark`) and Sector table is unused. First entry of Extension table specifies
  the number of sectors (multiplied by 29) that the file occupies. This implementation
  of MinimalFilesystem always ensures every file occupies a power of two of sectors.
- When files are deleted or grow over their allocated sector count, they are replaced
  by holes (and possibly copied to the end of the file system).
- The end of the filesystem is marked by a sector with a `mark` of zero.

As a result, when in use, the filesystem is always growing. There is a module provided
that can be used to "defragment" such a filesystem, reclaiming the wasted space.

There is an intermediate filesystem version available which does not change the on disk
structure (while changing the kernel interface) to make recompiling the system easier.
It also is able to read a minimal filesystem (if present) and convert to a normal
filesystem at bootup.


Installation
------------

- In case your filesystem image is larger than 1MB, delete some files and defragment it.

- Apply [`IntermediateFilesystem.patch`](IntermediateFilesystem.patch) to `FileDir.Mod`.

- Recompile `FileDir.Mod` and rebuild the whole system (including the compiler):

      ORP.Compile FileDir.Mod/s Files.Mod/s Modules.Mod/s ~
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

- Restart the system. (In case your emulator crashes due to out of bounds disk access,
  pad the filesystem to more than 1MB with zeroes).

- Apply [`MinimalFilesystem.patch`](MinimalFilesystem.patch) to (original) `FileDir.Mod`
  and`Files.Mod`.

- Push [`MinimalFilesystem.Mod.txt`](MinimalFilesystem.Mod.txt) and the patched
  `FileDir.Mod` and `Files.Mod`, compile them, and rebuild the inner core again:

      ORP.Compile MinimalFilesystem.Mod/s FileDir.Mod Files.Mod ~
      ORL.Link Modules ~
      ORL.Load Modules.bin ~

- Create the Minimal Filesystem:

      MinimalFilesystem.Create ~

- Restart the system. When you want to compact the filesystem after some usage, run

      MinimalFilesystem.Compact

  and restart the system.

Removal
-------

- Apply [`IntermediateFilesystem.patch`](IntermediateFilesystem.patch) to
  (original) `FileDir.Mod` and restore (original) `Kernel.Mod`.

- Rebuild the inner core:

      ORP.Compile FileDir.Mod Files.Mod ~
      ORL.Link Modules ~
      ORL.Load Modules.bin ~

- Restart the system. The filesystem is being converted back. You may now
  optionally remove IntermediatFileystem.patch as well.
