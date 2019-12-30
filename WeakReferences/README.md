WeakReferences - Add weak references to the Project Oberon 2013 kernel

Description
-----------

The `Files.Mod` module uses an interesting technique (in cooperation with the
garbage controller) to provide Files that will be garbage collected when they
are no longer (strongly) referenced, but stay available as long as they are
referenced.

Other garbage-collected languages know these kinds of reference as weak reference.

This modification will add weak references to the Kernel, and modify `Files.Mod`
to use these weak references instead of building their own.

To use the weak references, create new pointers to `Kernel.WeakReferenceDesc` or
type extensions of that type. After having assigned the `target` field, call
`Kernel.AddWeakReference`. Once the target is no longer strongly reached, the garbage
collector will set it to zero. Once you try to follow a weak reference and its target
is zero, you will have to clean up your data structure yourself (the WeakReferenceDesc
pointer will survive, only the target will get collected).

You can see the changed `Files.Mod` for an example how to use these weak references.


Installation
------------

- Apply [`WeakReferences.patch`](WeakReferences.patch) to `Kernel.Mod`, `Files.Mod` and `Oberon.Mod`.

- Recompile `Kernel.Mod` and rebuild the whole system (including the compiler):

      ORP.Compile Kernel.Mod/s FileDir.Mod/s Files.Mod/s Modules.Mod/s ~
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

- Restart the system.
