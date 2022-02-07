SeamlessResize - Automatically resize the Oberon system when emulator window is resized

Description
-----------

**NOTE**: Unlike other modifications, this modification is not standalone. It requires that
you applied the [HardwareEnumerator](../HardwareEnumerator/README.md) modification,
before this modification.

You may know this from other emulators: When you resize the emulator window, the
guest operating system is automatically resized. This modification provides this
behaviour for Oberon; it requires your Emulator to support the Hardware Enumerator,
the `mDyn` hardware descriptor, as well as seamless resize.

Internally, an Oberon Task is run every 5 minutes, which will trigger the automatic
resize, if needed.


Installation
------------

- Apply [HardwareEnumerator](../HardwareEnumerator/README.md), if not already applied.

- Push [`SeamlessResize.Mod.txt`](SeamlessResize.Mod.txt).

- Compile the new module:

      ORP.Compile SeamlessResize.Mod/s ~

- Run `SeamlessResize.Run` and enjoy your seamlessly resizing Oberon system.
