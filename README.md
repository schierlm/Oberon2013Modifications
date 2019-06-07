## Oberon 2013 Modifications

Here you can find modifications (I deliberately do **not** call them *enhancements*) I did to Project Oberon 2013.


Unlike the Oberon modules [in the `OberonEmulator` repository](https://github.com/schierlm/OberonEmulator/tree/master/Oberon),
these modifications do not depend on my emulator and may be used on any emulator or even on bare metal.

Some modifications require recompiling the *inner core*, or even recompiling the bootloader,
but those requirements are clearly listed in the accompanying `README.md` file.

To recompile and link the inner core, you can use
[Andreas Pirklbauer's Boot Linker](https://github.com/andreaspirklbauer/Oberon-building-tools/blob/master/Sources/OriginalOberon2013/Boot.Mod),
which is (for convenience; it is impossible to use that repo as a submodule as it is frequently rebased) also available [in this repo](Boot.Mod.txt).

### Available modifications

| Name/Link | Short description | Requirements |
|:--------- |:----------------- |:------------ |
| **[ConvertEOL](ConvertEOL/README.md)** | Convert line terminators when loading text files as ASCII | Recompile `Texts.Mod` |
| **[MinimalFonts](MinimalFonts/README.md)** | Minimal Fonts modules with a single font embedded to save space and avoid filesystem access | Recompile `Fonts.Mod` |
| **[RescueSystem](RescueSystem/README.md)** | Boot into secondary inner core in case main one is unable to boot | Compile two inner cores, move filesystem offset |
| **[DrawAddons](DrawAddons/README.md)** | More features for Oberon Draw | Optionally recompile `Graphics.Mod` |
| **[Calculator](Calculator/README.md)**| Simple prefix notation calculator | None |
| **[ResourceMonitor](ResourceMonitor/README.md)**| Continually display module space and heap usage | None |
