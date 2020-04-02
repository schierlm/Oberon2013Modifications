## Oberon 2013 Modifications

Here you can find modifications (I deliberately do **not** call them *enhancements*) I did to Project Oberon 2013.


Unlike the Oberon modules [in the `OberonEmulator` repository](https://github.com/schierlm/OberonEmulator/tree/master/Oberon),
these modifications do not depend on my emulator and may be used on any emulator or even on bare metal.

Some modifications require recompiling the *inner core*, or even recompiling the bootloader,
but those requirements are clearly listed in the accompanying `README.md` file.

To recompile and link the inner core, you can use
[Andreas Pirklbauer's Boot Linker](https://github.com/andreaspirklbauer/Oberon-building-tools/blob/master/Sources/FPGAOberon2013/ORL.Mod),
which is (for convenience; it is impossible to use that repo as a submodule as it is frequently rebased) also available [in this repo](ORL.Mod.txt).

### Available modifications

Modifications marked with a † are not included in the prebuilt release. Either they collide with other modifications, they need
larger changes to the system which cannot be done by recompiling a few files and writing a new inner core,or they are not
designed to be used on a day-by-day basis.

| Name/Link | Short description | Requirements |
|:--------- |:----------------- |:------------ |
| **[BugFixes](BugFixes/README.md)** | Fixes for what I consider to be bugs | Optionally recompile inner core |
| **[ConvertEOL](ConvertEOL/README.md)** | Convert line terminators when loading text files as ASCII | Recompile `Texts.Mod` |
| **[MinimalFonts](MinimalFonts/README.md)**† | Minimal Fonts modules with a single font embedded to save space and avoid filesystem access | Recompile `Fonts.Mod` |
| **[RescueSystem](RescueSystem/README.md)**† | Boot into secondary inner core in case main one is unable to boot | Compile two inner cores, move filesystem offset |
| **[DrawAddons](DrawAddons/README.md)** | More features for Oberon Draw | Optionally recompile `Graphics.Mod` |
| **[Calculator](Calculator/README.md)**| Simple prefix notation calculator | None |
| **[ResourceMonitor](ResourceMonitor/README.md)**| Continually display module space and heap usage | None |
| **[DefragmentFreeSpace](DefragmentFreeSpace/README.md)** | Defragment all files and move them to the beginning of the filesystem | Recompile inner core |
| **[RealTimeClock](RealTimeClock/README.md)** | Add a "ticking" real-time clock that is updated on demand based on `Kernel.Time` | Recompile inner core |
| **[DoubleTrap](DoubleTrap/README.md)** | Detect when a trap occurs in the trap handler and work around it | Minimal: Recompile `System.Mod`; Full: Recompile inner core |
| **[MinimalBootstrapSystem](MinimalBootstrapSystem/README.md)**† | Minimal disk image that can be used to bootstrap/compile the normal system | Recompile everything except inner core |
| **[OnScreenKeyboard](OnScreenKeyboard/README.md)** | Little keyboard on the screen when no real keyboard is available | Recompile `Input.Mod` and dependant modules |
| **[WeakReferences](WeakReferences/README.md)** | Add weak references to the Project Oberon 2013 kernel | Recompile inner core |
| **[RebuildToolBuilder](RebuildToolBuilder/README.md)**| Build a list of modules that need to be rebuilt | None |
| **[KeyboardTester](KeyboardTester/README.md)** | Test if all keys on your (emulated) keyboard work | None |
| **[RemoveFloatingPoint](RemoveFloatingPoint/README.md)**† | Build an Oberon system without Floating Point support | Recompile inner core |
| **[RobustTrapViewer](RobustTrapViewer/README.md)** | Make sure TRAPs in system modules are seen | None (load it manually) |
| **[TrapBacktrace](TrapBacktrace/README.md)** | Print a backtrace on TRAP and ABORT | Optionally update the boot loader |
| **[ZeroLocalVariables](ZeroLocalVariables/README.md)** | Zero local variables to avoid memory corruption due to uninitialized variables | Recompile `ORG.Mod` |
| **[VariableLinespace](VariableLinespace/README.md)** | Support lines of different height in the same Text viewer | Recompile `TextFrames.Mod` |
| **[UTF8Charset](UTF8Charset/README.md)**† | Display UTF-8 characters in a Text viewer | Recompile outer core and compiler |
| **[UTF8CharsetLite](UTF8CharsetLite/README.md)** | UTF-8 support, limited to special Unicode text viewers | Recompile `Fonts.Mod` |
| **[RemoveFilesizeLimit](RemoveFilesizeLimit/README.md)**| Remove the 3MB file size limit | Recompile inner core |
| **[ORInspect](ORInspect/README.md)** | Inspect global module variables and heap pointers | Recompile compiler and all modules you want to inspect |
| **[StackOverflowProtector](StackOverflowProtector/README.md)** | Trigger TRAP 9 at stack overflows | Recompile inner core |