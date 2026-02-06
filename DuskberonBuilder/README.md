DuskberonBuilder - Build an Oberon disk image using Dusk OS's Oberon compiler written in Forth

Description
-----------

[Dusk OS](http://duskos.org) comes with an Oberon compiler written in Forth that can be used
to compile basic Oberon files (no nested PROCEDURES, for example, and quite small stack) to
run in Dusk OS.

This modification patches the ORP RISC5 compiler to work under these limitathions. It also provides
scripts that layout the filesystem as needed (Dusk OS only supports 8.3 file names) and includes
an .ort Tool file that shows the steps to build it. Image tools are also included which are used
to compile a basic Oberon system (with modifications) and create a disk image that can be run
in Dusk OS's included RISC5 emulator.

Due to the filesystem limitation, only the outer core of the sources is added as individual files
to the Dusk OS file tree, all the other files are concatenated to a large file and unpacked
by [`Unpack.Mod`)(Unpack.Mod] in the resulting system.

This process has been tested with [v26](https://git.sr.ht/~vdupras/duskos/refs/v26) with
[this](https://git.sr.ht/~vdupras/duskos/commit/0f8231562f515303512a34851f48dccd81fcfc16) and
[this](https://git.sr.ht/~vdupras/duskos/commit/94a6ebe8eea5d8bf10f42ef6d2f7c26ad362003c) patch applied.

Building
--------

- Run  [`prepare_files.sh`](prepare_files.sh) to create the required directory tree in `work/fs`.

- Copy these files into an existing Dusk OS image.

- Inside Duskberon, load [`compile.ort`](compile.ort) and follow its steps.

- Load the resulting `oberon.dsk` in the RISC5 emulator. It will automatically show
  [`System0.Tool`](System0.Tool) which includes the final steps of unpacking and compiling
  the rest of the system.

- Restart the emulator once done.
