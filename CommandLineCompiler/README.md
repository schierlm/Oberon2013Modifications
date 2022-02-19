CommandLineCompiler - Run the Oberon compiler in a command line emulator

Description
-----------

Modern development practices include Continuous Integration - automatically building
every commit to source control and every pull request, to make sure that build breakage
is found early (or even not merged at all).

But how do you compile a project where the only interface to the compiler is a
graphical one? The [CommandExitCodes](../CommandExitCodes/README.md) modification
is the first step; now you can detect if a build fails. So the only second step is
an Oberon system that can invoke (at least) the compiler from the command line.

This is designed around a patched version of
[Peter de Wachter's oberon-risc-emu](https://github.com/pdewacht/oberon-risc-emu/).
Standard input is forwarded to the serial port line-by-line, and the serial port is forwarded
to standard output. Some special sequences are used to indicate to the emulator when
another input line is needed and/or whether an error occured. This will pause the
emulation while waiting for user input.

Lines starting with a `+` are treated specially, in that the emulator will append the
content of the file with same name to the serial port message. Other lines are executed
using `TextFrames.Call`.

An Oberon module will then interpret those serial commands and execute them, until
there are no more commands, when the emulator will stop.

As you can pass a disk image to the emulator, this can also be used to recompile the
whole system automatically.


Installation
------------

- Get the following files from
  [Peter de Wachter's oberon-risc-emu](https://github.com/pdewacht/oberon-risc-emu/tree/master/src):
  - disk.c
  - disk.h
  - risc.c
  - risc.h
  - risc-boot.inc
  - risc-fp.c
  - risc-fp.h
  - risc-io.h

- Compile the emulator:
  `gcc main.c disk.c risc.c risc-fp.c -o risc`
  (for Windows: `i686-w64-mingw32-gcc main.c disk.c risc.c risc-fp.c -o risc.exe`)

- Apply [CommandExitCodes](../CommandExitCodes/README.md), if not already applied.

- Push [`CommandLineSystem.Mod.txt`](CommandLineSystem.Mod.txt).

- To automatically load the command line system, use the [StartupCommand](../StartupCommand/README.md)
  modification.

- Compile the module:

      ORP.Compile CommandLineSystem.Mod/s  ~

- Restart the system
