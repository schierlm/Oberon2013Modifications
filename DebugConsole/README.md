DebugConsole - Write debug strings to MMIO address and view them in emulator output

Description
-----------

**NOTE**: Unlike other modifications, this modification is not standalone. It requires that
you applied the [HardwareEnumerator](../HardwareEnumerator/README.md) modification,
before this modification.

When debugging your Oberon programs (without a [kernel debugger](../KernelDebugger/README.md),
you can output things to Oberon.log. Unless you are trying to debug code that
lives "lower" in the dependency stack than Texts.Mod (or even in the inner core
or bootloader). The only options there are 8 LEDs that you can flash.

When developing on an emulator, the emulator usually has some standard output
(or JavaScript console in case of an emulator in the browser) which provides
far more feedback than 8 LEDs. Therefore, some emulators provide a Debug Console
MMIO address: When you write a character to it, it gets appended to a buffer,
which gets "logged"/flushed once the next `0X` char appears. The address of
this debug console is negotiated via the hardware enumerator's `DbgC` descriptor.

This modification provides procedures `ConsoleCh`, `ConsoleHex`, `ConsoleStr`,
`ConsoleLn` and `ConsoleFlush` in the `Kernel` module, as well as a `Console`
module which provides functionality to log an arbitrary `Texts.Text`, `Texts.Buffer`
in addition to a `Console.Log` command procedure which logs a delimited string
(using any delimiters) from its arguments (`^` is also supported).

Installation
------------

- Apply [HardwareEnumerator](../HardwareEnumerator/README.md), if not already applied.

- Apply [`DebugConsole.patch`](DebugConsole.patch) to `Kernel.Mod`.

- Push [`Console.Mod.txt`](Console.Mod.txt).

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

- Compile the new module:

      ORP.Compile Console.Mod/s ~

- Restart the system.
