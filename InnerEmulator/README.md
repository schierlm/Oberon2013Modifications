InnerEmulator - Emulate a RISC processor on the Oberon system


Description
-----------

This modification is not very useful by itself. It provides an Oberon RISC emulator
that is written in Oberon and (slowly) runs inside the Oberon RISC system.

However, it may act as a base for experimenting with JIT rewriting of instructions,
or for porting an Oberon emulator to a system written in Oberon (e.g. A2).

Its feature set is smaller than my JavaScript emulator; It only supports 1 MB of RAM,
black and white framebuffer, and its serial emulation is limited to either having
nothing connected or accessing the Host system's serial port.

At some points, it takes short cuts (the LEDs directly modify the LEDs of the
host system, the implementation of the `Mul` and `Div` commands heavily depends
on the fact that the host machine is also the same RISC machine, and the floating
point instructions also depend on the host machine having IEEE floats available).
But none of them are set in stone, all of them can be overcome with some effort.

One instruction variant (unsigned division) is not implemented at all, as the Oberon
compiler does not make use of it, and I do not know an easy way to implement it
efficiently with only the Oberon command set available (I'd probably do some shift
and subtract algorithm if I had to) on a 32-bit machine.

The screen appears in a viewer (which can be cloned etc, like any other viewer),
and keyboard and mouse input (as well as Esc and F1) are forwarded to the emulator.
Clipboard emulation is available and accesses the selection or writes to the Log
viewer.
Three commands, `Break`, `Reset` and `Stop`, are available in the viewer menu. When
running in a color host system, the background and foreground color can be set before
starting the emulator.

To obtain a disk image, export one from my JavaScript emulator (a black and white
one, with 1 MB RAM) and push it to the host system.


Installation
------------

- Push [`EmulatorCPU.Mod.txt`](EmulatorCPU.Mod.txt),
  [`EmulatorCore.Mod.txt`](EmulatorCore.Mod.txt),
  [`EmulatorFrames.Mod.txt`](EmulatorFrames.Mod.txt) and
  [`Emulator.Mod.txt`](Emulator.Mod.txt).

- Compile the new modules:

    ORP.Compile EmulatorCPU.Mod/s EmulatorCore.Mod/s ~
    ORP.Compile EmulatorFrames.Mod/s Emulator.Mod/s ~

- Use the commands in [`Emulator.Tool.txt`](Emulator.Tool.txt).
