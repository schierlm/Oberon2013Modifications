EmbeddableCompiler - Version of the Oberon RISC Compiler that does not (directly) depend on Fonts/Texts/Oberon

Description
-----------

The official version of the Oberon RISC compiler is tightly coupled to the Texts (and
therefore Fonts) and Oberon (and therefore Input, Display, Viewers) modules. When
having an Oberon compiler in an embedded environment, having these modules around
without having an actual display, or capabilities to show fonts, may be undesired.

This modification modifies the Oberon RISC compiler so that its basic modules (ORS,
ORB, ORG, ORP) only depend on the inner core as well as a stripped-down ORTexts module
that only supports reading and only supports plain text files stored on disk.

An additional module ORCompiler provides the entry point for a full Oberon system
(but, obviously, only supporting plain text and not supporting compilation from an
unsaved Viewer). This module again depends on Texts and Oberon, but it is only about
60 lines long and easy to change.

Installation
------------

- Apply [`EmbeddableCompiler.patch`](EmbeddableCompiler.patch) to `ORS.Mod` and `ORP.Mod`.

- Push [`ORTexts.Mod.txt`](ORTexts.Mod.txt) and  [`ORCompiler.Mod.txt`](ORCompiler.Mod.txt).

- Recompile the compiler:

      ORP.Compile ORTexts.Mod/s ~
      ORP.Compile ORS.Mod/s ORB.Mod/s ~
      ORP.Compile ORG.Mod/s ORP.Mod/s ~
      ORP.Compile ORCompiler.Mod/s ~

- Restart the system.

- Use `ORCompiler.Compile` instead of `ORP.Compile` now to compile modules (text only).
