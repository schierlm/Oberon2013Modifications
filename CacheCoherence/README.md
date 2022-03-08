CacheCoherence - Invalidate code cache after loading modules

Description
-----------

**NOTE**: Unlike other modifications, this modification is not standalone. It requires that
you applied the [HardwareEnumerator](../HardwareEnumerator/README.md) and
[DebugConsole](../DebugConsole/README.md) modifications,
before this modification.

In February, 2022, it was discussed on the Oberon mailing list, that when designing
a new board to run Project Oberon, it may require to have separate independent
code and data caches. When a new module is loaded, these caches can become incoherent,
resulting in running the wrong code; therefore there must be a way to invalidate
the code cache, which is called (among other places) when a new module is loaded.

This may also be helpful when implementing emulators that do just-in-time code translation,
as the same method can be used to flush the code translation tables.

As "hardware interface", a MMIO address (enumerated via hardware enumerator) can be
written to. When the address is written to, all code caches for addresses larger
or equal to the written value need to get invalidated. Software is free to always write
zero to invalidate all caches, and hardware is free to always invalidate all caches
on a write without looking at the value written.

This modification introduces the required changes to Project Oberon.

Installation
------------

- Apply [HardwareEnumerator](../HardwareEnumerator/README.md) and
  [DebugConsole](../DebugConsole/README.md), if not already applied.

- Apply [`CacheCoherence.patch`](CacheCoherence.patch) to `Kernel.Mod` and `Modules.Mod`.

- In case you want to use the dynamic memory split, apply
  [`DynamicMemorySplit.patch`](DynamicMemorySplit.patch) to `System.Mod`.

- In case you want to use the rescue system, apply [`RescueSystem.patch`](RescueSystem.patch)
  to `RescueSystemLoader.Mod`.

- In case you want to use the kernel debugger, apply [`KernelDebugger.patch`](KernelDebugger.patch)
  to `DebugStub.Mod` and `DebugStubTest.Mod`.

- Recompile the whole system (including the compiler):

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
