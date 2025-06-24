RealTimeClock - Add a "ticking" real-time clock that is updated on demand based on `Kernel.Time`

Description
-----------

Project Oberon provides a "real-time clock" that can be queried and set by `System.Date`.
It is used for creating timestamps for files.

However, the clock is not ticking - when set, it remains at the set time, and when unset,
it is `00.00.00 00:00:00`.

This patch can be used to get a ticking real-time clock. However, this is not done by
a task that wakes up the CPU every minute just to update the clock; instead the kernel
function to get the time is patched to update the clock depending on `Kernel.Time` ticks.

When you are using an emulator that supports the hardware enumerator's `vRTC` record, you
can apply the hardware enumerator patches and will always have a correct "ticking" real-time
clock without having to set it manually.


Installation
------------

- Apply [`RealTimeClock.patch`](RealTimeClock.patch) to `Kernel.Mod`.

- Recompile `Kernel.Mod` and rebuild the inner core:

      ORP.Compile Kernel.Mod FileDir.Mod Files.Mod Modules.Mod ~
      ORL.Link Modules ~
      ORL.Load Modules.bin ~


- Restart the system.

- Enjoy a correct time when you run `System.Date ~`