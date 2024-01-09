![Build Disk Image](https://github.com/schierlm/Oberon2013Modifications/workflows/Build%20Disk%20Image/badge.svg)
[![Latest Release](https://img.shields.io/badge/Download-Release%202020.05-blue)](https://github.com/schierlm/Oberon2013Modifications/releases/tag/2020.05)
[![Latest Automated Build](https://img.shields.io/badge/Download-Latest%20Automated%20Build-blue)](https://github.com/schierlm/Oberon2013Modifications/releases/tag/automatedbuild)

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
larger changes to the system which cannot be done by recompiling a few files and writing a new inner core, or they are not
designed to be used on a day-by-day basis.

The CommandLineCompiler is available as a separate release.

Modifications marked with a ‡ are only included in the prebuilt "debug release". These modifications aid in debugging, but have
a high performance or binary size overhead, and are therefore undesirable in normal builds.

There are also two separate releases available that include the rescue system (the normal one and the "debug" one).

In case you want to pick & patch your own modifications, you can obtain the unpatched original
files from the [wirth-personal](https://github.com/Spirit-of-Oberon/wirth-personal) repository.
The scripts in this repo assume that the other repo is located at `../wirth-personal`; if it is not,
you can override the location using the `WIRTH_PERSONAL` environment variable.

The `get_unpatched_source.sh` script collects the files to be patched into `work` directory,
the `make_release.sh` also applies the releease patches to it, and the `make_disk_image.sh`
script expects patched sources in `work` directory and builds a disk image from them.

| Name/Link | Short description | Requirements |
|:--------- |:----------------- |:------------ |
| **[BiSixelFont](BiSixelFont/README.md)**| Display small images in Text frames | None |
| **[BugFixes](BugFixes/README.md)** | Fixes for what I consider to be bugs | Optionally recompile inner core |
| **[CacheCoherence](CacheCoherence/README.md)**| Invalidate code cache after loading modules | Recompile inner core |
| **[Calculator](Calculator/README.md)**| Simple prefix notation calculator | None |
| **[ChangeResolution](ChangeResolution/README.md)** | Dynamically change the display resolution if the driver supports it | Recompile outer core |
| **[Clock](Clock/README.md)** | Show a clock in the lower right corner | None |
| **[ColorPalette](ColorPalette/README.md)** | Display and edit the color palette | Color Support |
| **[ColorSupport](ColorSupport/README.md)** | Support both monochrome and 16-color modes | Hardware Enumerator |
| **[ColorTheme](ColorTheme/README.md)** | Configure which colors are used for UI elements | BugFixes |
| **[CommandExitCodes](CommandExitCodes/README.md)** | Let commands return an exit code so that scripts can react to it | Recompile outer core |
| **[CommandLineCompiler](CommandLineCompiler/README.md)**† | Run the Oberon compiler in a command line emulator | Patch emulator |
| **[ConvertEOL](ConvertEOL/README.md)** | Convert line terminators when loading text files as ASCII | Recompile `Texts.Mod` |
| **[CrossCompiler](CrossCompiler/README.md)** | Compile a second set of modules without affecting the current system | Recompile compiler |
| **[CursorKeys](CursorKeys/README.md)** | Support cursor keys in TextFrames and GraphicFrames | Recompile affacted outer core modules |
| **[DebugConsole](DebugConsole/README.md)** | Write debug strings to MMIO address and view them in emulator output | Hardware Enumerator |
| **[DefragmentFreeSpace](DefragmentFreeSpace/README.md)** | Defragment all files and move them to the beginning of the filesystem | Recompile inner core |
| **[DoubleTrap](DoubleTrap/README.md)** | Detect when a trap occurs in the trap handler and work around it | Minimal: Recompile `System.Mod`; Full: Recompile inner core |
| **[DrawAddons](DrawAddons/README.md)** | More features for Oberon Draw | Optionally recompile `Graphics.Mod` |
| **[DynamicMemorySplit](DynamicMemorySplit/README.md)** | Move the address that separates heap from stack and modules | Rebuild inner core |
| **[EditImprovements](EditImprovements/README.md)** | Edit.Locate and ~.Search display the target location in the first line of the viewer | Recompile Edit.Mod |
| **[EmbeddableCompiler](EmbeddableCompiler/README.md)**† | Version of the Oberon RISC Compiler that does not (directly) depend on Fonts/Texts/Oberon | None |
| **[FontConversion](FontConversion/README.md)** | Conversions to and between Oberon .Scn.Fnt files | Optionally patch Display.Mod |
| **[HardwareEnumerator](HardwareEnumerator/README.md)** | Make disk images hardware independent by enumerating hardware at startup | Recompile inner core |
| **[HostTransfer](HostTransfer/README.md)** | Allow systems within emulators to copy files from/to the host | Hardware Enumerator |
| **[ImageBuilder](ImageBuilder/README.md)** | Build disk images | None |
| **[InnerEmulator](InnerEmulator/README.md)** | Emulate a RISC processor on the Oberon system | None (except patience when starting it up) |
| **[KernelDebugger](KernelDebugger/README.md)**‡ | Debug and inspect one RISC5 machine from another one via serial link | Apply ORStackInspect; recompile everything including inner core |
| **[KeyboardTester](KeyboardTester/README.md)** | Test if all keys on your (emulated) keyboard work | None |
| **[LanguageServerProtocolHelper](LanguageServerProtocolHelper/README.md)** | Backend service for an Oberon LSP Server | None |
| **[LargeFilesystem](LargeFilesystem/README.md)**† | Filesystem with 64 character filenames and 4 KB sectors | Recompile inner core and rebuild filesystem |
| **[LSPUtil](LSPUtil/README.md)** | Reformat or highlight Oberon source inside the system | LanguageServerProtocolHelper |
| **[MinimalBootstrapSystem](MinimalBootstrapSystem/README.md)**† | Minimal disk image that can be used to bootstrap/compile the normal system | Recompile everything except inner core |
| **[MinimalFilesystem](MinimalFilesystem/README.md)**† | Minimalistic filesystem code storing just a sequence of files with delete markers | Recompile inner core and rebuild filesystem |
| **[MinimalFonts](MinimalFonts/README.md)**† | Minimal Fonts modules with a single font embedded to save space and avoid filesystem access | Recompile `Fonts.Mod` |
| **[ORInspect](ORInspect/README.md)** | Inspect global module variables and heap pointers | Recompile compiler and all modules you want to inspect |
| **[ORStackInspect](ORStackInspect/README.md)**‡ | Inspect stack variables when printing a backtrace | Apply DoubleTrap, TrapBacktrace, ZeroLocalVariables and ORInspect; recompile everything including inner core |
| **[OnScreenKeyboard](OnScreenKeyboard/README.md)** | Little keyboard on the screen when no real keyboard is available | Recompile `Input.Mod` and dependant modules |
| **[RealTimeClock](RealTimeClock/README.md)** | Add a "ticking" real-time clock that is updated on demand based on `Kernel.Time` | Recompile inner core |
| **[RebuildToolBuilder](RebuildToolBuilder/README.md)**| Build a list of modules that need to be rebuilt | None |
| **[RemoveFilesizeLimit](RemoveFilesizeLimit/README.md)**| Remove the 3MB file size limit | Recompile inner core |
| **[RemoveFloatingPoint](RemoveFloatingPoint/README.md)**† | Build an Oberon system without Floating Point support | Recompile inner core |
| **[ReproducibleBuild](ReproducibleBuild/README.md)**† | How to build Oberon disk images that are bit-for-bit identical | Recompile everything |
| **[RescueSystem](RescueSystem/README.md)**† | Boot into secondary inner core in case main one is unable to boot | Compile two inner cores, move filesystem offset |
| **[ResourceMonitor](ResourceMonitor/README.md)**| Continually display module space and heap usage | None |
| **[RobustTrapViewer](RobustTrapViewer/README.md)** | Make sure TRAPs in system modules are seen | None (load it manually) |
| **[Scripting](Scripting/README.md)** | Run multiple commands and react on their outcome | Apply `CommandExitCodes` |
| **[SeamlessResize](SeamlessResize/README.md)** | Automatically resize the Oberon system when emulator window is resized | Hardware Enumerator |
| **[StackOverflowProtector](StackOverflowProtector/README.md)** | Trigger TRAP 9 at stack overflows | Recompile inner core |
| **[StartupCommand](StartupCommand/README.md)** | Run a command (from System.Tool) when Oberon starts | Recompile System.Mod |
| **[TrapBacktrace](TrapBacktrace/README.md)** | Print a backtrace on TRAP and ABORT | Optionally update the boot loader |
| **[UnicodeFontIndex](UnicodeFontIndex/README.md)** | Speed up partial loading of Unicode fonts | Recompile `Fonts.Mod` |
| **[UTF8CharsetLite](UTF8CharsetLite/README.md)** | UTF-8 support, limited to special Unicode text viewers | Recompile `Fonts.Mod` |
| **[UTF8Charset](UTF8Charset/README.md)**† | Display UTF-8 characters in a Text viewer | Recompile outer core and compiler |
| **[VariableLinespace](VariableLinespace/README.md)** | Support lines of different height in the same Text viewer | Recompile `TextFrames.Mod` |
| **[WeakReferences](WeakReferences/README.md)** | Add weak references to the Project Oberon 2013 kernel | Recompile inner core |
| **[ZeroLocalVariables](ZeroLocalVariables/README.md)** | Zero local variables to avoid memory corruption due to uninitialized variables | Recompile `ORG.Mod` |
