DefragmentFreeSpace - Defragment all files and move them to the beginning of the filesystem

Description
-----------

When working in an emulator, emulator images can grow bigger than they have to be.
With Oberon's tiny filesystems this is not a very big problem, but when sharing
disk images with others, it can be helpful to remove unneccessary and potentially
private information. Also when sharing disk images for my JavaScript emulator,
it makes sense to defragment them first.

As the `Kernel` does not expose the last used sector of the filesystem, a small patch to
`Kernel.Mod` is required (and a rebuild of the inner core) if you want to use the
Defragmenter.

After defragmentation, the second step is to trim the filesystem at the last used sector.
Therefore, the defragmenter writes an extra sector containing

    !!TRIM!!---- … ---!!TRIM!!

after the last used sector. This sector is detected by my emulators to trim the image
automatically; if yours does not, you can use the [`trim_defragmented_image.sh`](trim_defragmented_image.sh)
shell script instead.


There are two defragmenters available. The **Lite** version keeps a list of files in RAM,
and can therefore only used if lots of RAM is available or there are only very few files.
Also, opening and closing files will allocate buffer records and index records in `Files.Mod`;
therefore even if the file list was stored on disk, garbage would accumulate until the GC runs
next time (which only happens as a background task when the system is idle). To slightly reduce
this problem, the Lite defragmenter can run in two phases: The first one `Defragger.Prepare` will
copy file contents to the end of the disk, and the second pass `Defragger.Defrag` will nuke the
filesystem and create a fresh one (In case the first pass is not called, the second pass will
run the first one as well).

As this is no real option on systems with 1MB RAM and lots of files, there is another version
of the Defragmenter available. It keeps a file list on disk (after the end of the filesystem),
and uses a custom version of `Files.Mod` called [`DefragFiles.Mod`](DefragFiles.Mod.txt), which
can only open one file at a time, but does not need to do any allocations at runtime.

Installation
------------

- Apply [`DefragSupport.patch`](DefragSupport.patch) to `Kernel.Mod`.

- Push the new modules.

- Recompile `Kernel.Mod` and rebuild the whole system (including the compiler):

      ORP.Compile Kernel.Mod/s FileDir.Mod/s Files.Mod/s Modules.Mod/s ~
      Boot.Link Modules ~
      Boot.Load Modules.bin ~

      ORP.Compile Input.Mod/s Display.Mod/s Viewers.Mod/s ~
      ORP.Compile Fonts.Mod/s Texts.Mod/s ~
      ORP.Compile Oberon.Mod/s ~
      ORP.Compile MenuViewers.Mod/s ~
      ORP.Compile TextFrames.Mod/s ~
      ORP.Compile System.Mod/s ~
      ORP.Compile Edit.Mod/s ~
      ORP.Compile ORS.Mod/s ORB.Mod/s ~
      ORP.Compile ORG.Mod/s ORP.Mod/s ~

- Compile the new modules:

      ORP.Compile DefragFiles.Mod/s Defragger.Mod/s ~

  or

      ORP.Compile Defragger.Lite.Mod/s ~

- Restart the system.

- In case you are using the Lite version, run `Defragger.Prepare` and `System.Collect`.

- Run `Defragger.Defrag`.
