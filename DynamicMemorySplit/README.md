DynamicMemorySplit - Move the address that separates heap from stack and modules

Description
-----------

In the original Oberon 2013 design, the boot ROM is responsible to define the
memory layout. The first region will contain loaded modules (growing downwards)
and stack (growing upwards), the second region contains the heap, and the third
region contains the framebuffer and I/O space. It makes sense to define the
framebuffer and I/O space in the bootloader, yet it may be useful to move the
split between the modules/stack region and the modules region on the same
hardware without rewriting the boot loader. This is especially true on systems
with more than 1MB of RAM, as some workloads need a larger heap and others need
more stack or more loaded modules.

This is implemented in the Modules module, which is the first module that is
executed, and can still easily move the stack around. Memory address 4 is still
unused, therefore a new MemorySplit module can write the desired split position
there. This value is loaded by the Modules module, and after some validity checks
(there should be at least 192 KB of modules/stack and 256 KB of heap remaining)
moves the stack pointer register and the memory address 24 which contains the
boot loader's desired split.

One problem remains: On a soft reset (Abort), the boot loader will initialize the
stack pointer to point at the old memory split location again, which may now lie
inside the heap. The Abort handler will initialize its stack frame and overwrite
precious values from the heap. Therefore, the Abort handler is changed to point
to a Trampoline which will first "restore" the stack pointer (if inside the heap)
to a safe value, then jump to the original Abort handler.

Installation
------------

- Apply [`DynamicMemorySplit.patch`](DynamicMemorySplit.patch) to `Modules.Mod`
  and `System.Mod`.

- Push [`MemorySplit.Mod.txt`](MemorySplit.Mod.txt).

- Compile the modules and rebuild the inner core:

      ORP.Compile Modules.Mod/s System.Mod/s MemorySplit.Mod/s ~
      ORL.Link Modules ~
      ORL.Load Modules.bin ~

- Set your desired Memory split values:

      MemorySplit.Set 60000H

- Restart the system.

- Check the memory split:

      MemorySplit.Show
