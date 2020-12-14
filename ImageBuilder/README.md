ImageBuilder - Build disk images

Description
-----------

Usually Oberon runs from a disk image (or real disk in case of real hardware). But
how can you create a disk image if you do not have one already (or one that is
vastly different)? You may try altering your current disk without destroying it,
or you may connect two emulators/machines via serial cable and use the
[Oberon building tools](https://github.com/andreaspirklbauer/Oberon-building-tools)
to build a new disk image. On the other hand, maybe you don't have a second machine
available (or are using Host FS in an emulator), but you have patched your filesystem
to [remove its limits](../RemoveFilesizeLimit/README.md), so you would prefer to build
"an image inside an image" and then use PCLink to copy out the image?

Then, this modification is for you. While it does not depend on other modifications,
it plays well with boot areas linked by `ORL.Mod` and automatically strips the `.X`
extension added by the [cross compiler](../CrossCompiler/README.md).

Installation
------------

- Create copies of `FileDir.Mod` and `Files.Mod` and name them
  `ImageFileDir.Mod` and `ImageFiles.Mod`.

- Apply [`DeriveImageFiles.patch`](DeriveImageFiles.patch) to `ImageFileDir.Mod`,
  and `ImageFiles.Mod`.

- Push the new modules.

- Compile the new modules:

      ORP.Compile ImageKernel.Mod/s ImageFileDir.Mod/s ~
      ORP.Compile ImageFiles.Mod/s ImageTool.Mod/s ~

- Use the commands in `ImageBuilder.Tool`.
