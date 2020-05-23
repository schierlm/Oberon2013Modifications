CommandExitCodes - Let commands return an exit code so that scripts can react to it

Description
-----------

Running batch jobs in Oberon is hard, as you have no way to automatically deterimine whether
the last command was successful. Most commands will print errors into the Log buffer, but since
that buffer does not only contains errors, it is hard to automatically determine whether logs
there are errors or not (My own `Batch.Mod`, which is not yet part of this repository, tries
to build checksums of the log buffer and compares them to the previous run...).

This can be made better. Let commands call `Oberon.SetRetVal` in case of an error, and batch jobs
can check `Oberon.RetVal` to find out.

Installation
------------

- Apply [`CommandExitCodes.patch`](CommandExitCodes.patch) to `Oberon.Mod`, `System.Mod`
  and `ORP.Mod`.

- Recompile `Oberon.Mod` and all dependencies (including the compiler):

      ORP.Compile Oberon.Mod/s ~
      ORP.Compile MenuViewers.Mod/s ~
      ORP.Compile TextFrames.Mod/s ~
      ORP.Compile System.Mod/s ~
      ORP.Compile Edit.Mod/s ~
      ORP.Compile ORS.Mod/s ORB.Mod/s ~
      ORP.Compile ORG.Mod/s ORP.Mod/s ~

- Restart the system.
