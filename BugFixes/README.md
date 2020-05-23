BugFixes - Fixes for what I consider to be bugs

Description
-----------

Here are some small bugfixes.


Fix 1: Aborting when module exceeds globals size
------------------------------------------------

A module may have at most 64 KB of global variables, as otherwise fixups to
exported variables may fail. Enforce this in the compiler.

Fix 2: Initializing of `GraphicFrames.TBuf` variable
----------------------------------------------------


When you delete text from a Drawing, the extra letters get moved into a `Texts.Buffer` called `Tbuf`.
Only that this buffer is never initialized, resulting in memory corruption if you delete enough text.


Fix 3: Avoid freelist corruption after memory allocation failure
----------------------------------------------------------------


When a memory of a small type from a large block fails, the system will still store
the "second half" of the null pointer into the free lists, resulting in memory corruption
as soon as these free lists are used.

Fix 4: Avoid illegal IO access (-4) when GC encounters NIL pointers
-------------------------------------------------------------------

As discussed on the mailing list (`PO: Illegal memory access in GC`), the garbage collector
will read from IO address -4 when it encounters a NIL pointer and tries to read the metadata
preceding the pointer. By default, IO address -4 is unused and will return 0, but better
to avoid these accesses if possible.

Installation
------------

- Apply [`CheckGlobalsSize.patch`](CheckGlobalsSize.patch) to `ORG.Mod`

- Apply [`InitializeGraphicFramesTbuf.patch`](InitializeGraphicFramesTbuf.patch) to `GraphicFrames.Mod`

- Apply [`NoMemoryCorruptionAfterMemoryAllocationFailure.patch`](NoMemoryCorruptionAfterMemoryAllocationFailure.patch) to `Kernel.Mod`

- Apply [`IllegalAccessInGC.patch`](IllegalAccessInGC.patch) to `Kernel.Mod`

- Recompile the changed modules and rebuild the inner core:

      ORP.Compile Kernel.Mod ~
      ORL.Link Modules ~
      ORL.Load Modules.bin ~

      ORP.Compile GraphicFrames.Mod ~
      ORP.Compile ORG.Mod ~

- Restart the system.
