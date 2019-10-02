BugFixes - Fixes for what I consider to be bugs

Description
-----------

Here are some small bugfixes.


Fix 1: Handling of aliased modules
----------------------------------


Consider these modules:

    MODULE M1; TYPE P1* = POINTER TO T1; T1* = RECORD x*: INTEGER END; END M1.
    MODULE M2; IMPORT M1; TYPE P2* = POINTER TO T2; T2* = RECORD(M1.T1) y*: INTEGER END; END M2.
    MODULE M3; IMPORT M1, M2; VAR x1: M1.P1; x2: M2.P2; BEGIN x1 := x2; END M3.
    MODULE M4; IMPORT Y1 := M1, Y2 := M2; VAR x1: Y1.P1; x2: Y2.P2; BEGIN x1 := x2; END M4.

Modules M1 to M3 compile, but M4 (which should do the same as M3) does not.


Fix 2: Initializing of `GraphicFrames.TBuf` variable
----------------------------------------------------


When you delete text from a Drawing, the extra letters get moved into a `Texts.Buffer` called `Tbuf`.
Only that this buffer is never initialized, resulting in memory corruption if you delete enough text.


Fix 3: Avoid freelist corruption after memory allocation failure
----------------------------------------------------------------


When a memory of a small type from a large block fails, the system will still store
the "second half" of the null pointer into the free lists, resulting in memory corruption
as soon as these free lists are used.

Installation
------------

- Apply [`FixAliasedModules.patch`](FixAliasedModules.patch) to `ORB.Mod`

- Apply [`InitializeGraphicFramesTbuf.patch`](InitializeGraphicFramesTbuf.patch) to `GraphicFrames.Mod`

- Apply [`NoMemoryCorruptionAfterMemoryAllocationFailure.patch`](NoMemoryCorruptionAfterMemoryAllocationFailure.patch) to `Kernel.Mod`

- Recompile the changed modules and rebuild the inner core:

      ORP.Compile Kernel.Mod ~
      Boot.Link Modules ~
      Boot.Load Modules.bin ~

      ORP.Compile GraphicFrames.Mod ~
      ORP.Compile ORB.Mod ~

- Restart the system.
