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

When allocation of a small type from a large block fails, the system will still store
the "second half" of the null pointer into the free lists, resulting in memory corruption
as soon as these free lists are used.


Fix 4: Avoid illegal IO access (-4) when GC encounters NIL pointers
-------------------------------------------------------------------

As discussed on the mailing list (`PO: Illegal memory access in GC`), the garbage collector
will read from IO address -4 when it encounters a NIL pointer and tries to read the metadata
preceding the pointer. On the original board and compatible ones, IO address -4 is unused and
will return 0. Boards that incorporate the hardware enumerator will use address -4 to query
hardware descriptors and a spurios read is harmless there as well. However, it is better to
avoid these accesses if possible.


Fix 5: Fix register index for non-constant set literals
-------------------------------------------------------

When compiling code like the following, which contains a set literal where the bounds are
not constant, the compiler emitted correct code to calculate the set literal, but remembered
the wrong register index, so the value was not correctly used.

```
MODULE Test;

  PROCEDURE Mask(a: SET; b: INTEGER): SET;
  RETURN a - {b .. b + 7}
  END Mask;

BEGIN
  ASSERT( Mask( {0..31}, 8 ) = {0..7, 16..31} )
END Test.
```


Fix 6: Fix scroll cursor corrupting the IO memory area
------------------------------------------------------

When dragging the mouse pointer to the top of the screen while scrolling, the scroll cursor
was drawn partially outside the screen and could corrupt the IO memory area.


Fix 7: Fix wrapped memory displacement when accessing heap objects larger than 512 KB
-------------------------------------------------------------------------------------

When running on a system with more than 1 MB of RAM, heap objects can be larger than 512 KB.
But you'd rather avoid it, since relative memory access instructions only support a displacement
of 512 KB. The original compiler just wrapped the displacement, resulting in memory corruption.

This fix makes displacements larger than 512 KB a compile time error, forcing the user to rewrite
their code instead of a hard to debug memory corruption at runtime.


Installation
------------

- Apply [`CheckGlobalsSize.patch`](CheckGlobalsSize.patch) to `ORG.Mod`

- Apply [`InitializeGraphicFramesTbuf.patch`](InitializeGraphicFramesTbuf.patch) to `GraphicFrames.Mod`

- Apply [`NoMemoryCorruptionAfterMemoryAllocationFailure.patch`](NoMemoryCorruptionAfterMemoryAllocationFailure.patch) to `Kernel.Mod`

- Apply [`IllegalAccessInGC.patch`](IllegalAccessInGC.patch) to `Kernel.Mod`

- Apply [`CompileSetLiterals.patch`](CompileSetLiterals.patch) to `ORG.Mod`

- Apply [`FixScrollCursorCorruption.patch`](FixScrollCursorCorruption.patch) to `TextFrames.Mod`

- Apply [`FixWrappedMemoryDisplacement.patch`](FixWrappedMemoryDisplacement.patch) to `ORG.Mod`

- Recompile the changed modules and rebuild the inner core:

      ORP.Compile Kernel.Mod ~
      ORL.Link Modules ~
      ORL.Load Modules.bin ~

      ORP.Compile TextFrames.Mod ~
      ORP.Compile GraphicFrames.Mod ~
      ORP.Compile ORG.Mod ~

- Restart the system.
