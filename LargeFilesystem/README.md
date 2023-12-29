LargeFilesystem - Filesystem with 64 character filenames and 4 KB sectors

Description
-----------

Oberon's original filesystem with its limits (64 MB filesystem size, ~3 MB file size)
is well-suited for small files. But when
[removing the limits](../RemoveFilesizeLimit/README.md), performance for large files
is pretty slow. Also, 32 character file names are sometimes too limited.

This modification provides an example how to increase the sector size to 4 KB, file
name length to 64 characters, while also increasing the size of internal structures
(128 extended entries per file header). These values are by no means optimal; they
serve as example values. If you want to use different values, it should suffice to
recalculate some values (e.g. number of directory entries per sector or header size)
and migrate the filesystem again.

It also provides a way, with the help of an intermediate
[MinimalFileystem](../MinimalFilesystem/README.md), to migrate data from
the original filesystem to the large one. Patches to only use it as a minimal
filesystem are also provided.


Installation
------------

- In case your filesystem image is larger than 4MB, delete some files and defragment it.

- Apply [`LargeFileystem.patch`](LargeFileystem.patch) to `Kernel.Mod`, `FileDir.Mod`,
  `Files.Mod`, `System.Mod` and `ORL.Mod`.

- Apply [`LargeIntermediateFilesystem.patch`](LargeIntermediateFilesystem.patch) to a copy
  of the (already patched) `FileDir.Mod`, naming the copy `FileDirI.Mod`.

- Push the changed files along with [`MigrateFilesystem.Mod.txt`](MigrateFilesystem.Mod.txt).

- Compile `MigrateFilesystem.Mod` and load it:

      ORP.Compile MigrateFilesystem.Mod/s ~
      MigrateFilesystem.Load ~

- Recompile the changed modules and rebuild the whole system (including the compiler):

      ORP.Compile Kernel.Mod/s FileDirI.Mod/s Files.Mod/s Modules.Mod/s ~
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
      ORP.Compile ORL.Mod/s ~

- Migrate the filesystem:

     MigrateFilesystem.Migrate ~

- Restart the system. (The filesystem will be converted back to normal on boot).

- Optionally, recompile the system again, using `FileDir.Mod` instead of `FileDirI.Mod`.
