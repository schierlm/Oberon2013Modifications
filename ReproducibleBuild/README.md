ReproducibleBuild - How to build Oberon disk images that are bit-for-bit identical

Description
-----------

Reproducible builds are builds that result in identical binaries, regardless when
and where they are compiled. Oberon disk images are generally not reproducible - they
are usually taken from an existing system, and depending on what state the system had before,
the disk image will not be bit-for-bit identical with other disk images.

The defragmentation support makes the situation better - but still, `FileDir` for example
does not clean out extra directory entries when a directory entry is split. And building
an inner core does not clean the end of module names after the null byte terminator.

The space at the end of files (cluster tips) or the inner core are also usually not
cleared.

Another pitfall arises from the fact that the floating point parsing code contains floating
point literals; any rounding error or bug in their values inside the compiler will propagate to
future compilers that are compiled with this compiler. If you suspect this may be the case,
`ReproducibleFloats.patch` is provided that changes `ORS.Mod` to calculate all floating point
literals at runtime. You can compile the original compiler with a compiler where this patch
is applied, to mitigate that issue.

This modification tries to work around these issues, so that everybody (given that they
use the same source) can get the same binaries.


Current hashes
--------------

When taking the source from [commit b9649d3 of the Wirth-Personal mirror
repo](https://github.com/Spirit-of-Oberon/wirth-personal/tree/b9649d310e668c31b09e44ec38d0b517765be0a2/people.inf.ethz.ch/wirth/ProjectOberon/Sources),
the resulting tar file (without metadata) has a sha256sum of `89b3e6cbd34a155fee84439e465da2d29adaeae78edcedd7c8eaa8cf3aa6ca25`,
and the final disk image has a hash sha256sum of `6c4d6e7dec9ee9b096a5d744e3a48757fd4dbb1545f81d31f4f6741c7430d1c6`.


Building
--------

- Apply [`ReproducibleORL.patch`](ReproducibleORL.patch) to `ORL.Mod`.

- Apply [`ReproducibleDefragger.patch`](ReproducibleDefragger.patch) to `DefragFiles.Mod` and `Defragger.Mod`.

- Push `BuildTools.Mod` and `BuildReproducibly.Tool`.

- Push all original sources.

- Follow the contents of [`BuildReproducibly.Tool`](BuildReproducibly.Tool).

For building with the command line compiler, you can call [`test-reproducible-build.sh`](test-reproducible-build.sh) instead.
The reproducibly built disk image ends up in your `work` directory.
