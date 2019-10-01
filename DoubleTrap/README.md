DoubleTrap - Detect when a trap occurs in the trap handler and work around it

Description
-----------

Some TRAPs (particularly ones that exhaust the free memory by allocating
unreferenced garbage) can get the system into a state where the handling of the TRAP
(printing information about the TRAP) needs more free memory than is available. In
that case, even pushing the reset button cannot get around the problem, as the Abort
vector also tries to allocate some memory before it reaches the point where the
garbage collector can clean up the memory again.

This can be easily demonstrated by compiling and running
[`TrapTester.Mod.txt`](TrapTester.Mod.txt).

There are two ways to work around this issue, both are implemented here.

The easier method is to have a flag to detect reentrance to the trap handler(s).
If reentrance happens, do not handle the trap immediately, but remember to print a
DOUBLE TRAP warning after the next GC run. This method can be implemented without
changing any exported symbols, which is done in
[`DoubleTrap.Minimal.patch`](DoubleTrap.Minimal.patch).

The obvious disadvantage of this method: Trap information is lost (especially
painful in case your trap information includes backtraces), and the trap is
signalled about a second after it happened.

The second method involves "sacrificed memory". After each GC, if not already
allocated, 1KB of heap is allocated into a "sacrifice" variable, which will be freed
at the beginning of the trap handler. This is usually sufficient memory for the trap
handler to run. In case it is not, the reentrance check is still present and will
avoid a total lockup at the expense of missing trap information.

This approach, implemented by [`DoubleTrap.Minimal.patch`](DoubleTrap.Minimal.patch),
needs a changed `Kernel.Mod`, as the memory model does not support freeing memory
outside a GC cycle. The kernel patch introduces a new function, `ForceFree`, which
takes the address of the type tag pointer at the beginning of the heap element, and
forcibly frees it. Therefore, to use it, you have to recompile the whole system.

Installation (minimal version)
------------------------------

- Apply [`DoubleTrap.Minimal.patch`](DoubleTrap.Minimal.patch) to `System.Mod`.

- Recompile `System.Mod`:

      ORP.Compile System.Mod ~

- Restart the system.


Installation (full version)
---------------------------

- Apply [`DoubleTrap.patch`](DoubleTrap.patch) to `Kernel.Mod`, `Oberon.Mod` and `System.Mod`.

- Rebuild the whole system (including the compiler):

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

- Restart the system.
