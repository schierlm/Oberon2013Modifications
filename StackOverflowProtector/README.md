StackOverflowProtector - Trigger TRAP 9 at stack overflows

Description
-----------

Oberon is quite robust against memory corruptions, and other modifications show that you
can make it even more robust. One thing that is not protected against are stack overflows;
the stack will grow inside the modules space and overwrite module code, usually resulting
in a system crash.

It is hard to improve this situation without imposing a performance penalty. So this
modification might slow your system down more than you want; but you are free to not
use it if your code is immune to stack overflows.

It is implemented by changing the compiler how it emits an instruction that decrements
the stack pointer. Instead of simply decrementing it, it verifies whether the new stack
pointer value will still be above the value stored at address 16 (during bootup this is
the size of the inner core, and `Modules.Mod` will overwrite it with an address 1KB past
the end of the modules space). If the new value is too small, TRAP 9 is triggered, before
decrementing the register.

The `System.Trap` procedure is modified that it subtracts 1024 from address 16 before it
handles the trap, and adds 1024 afterwards. `Oberon.Reset` also needs to restore this
value, since in most cases the trap handler never returns.

One small issue remains: The trap itself is a BLR instruction; therefore the trap
procedure's prolog also tries to decrement the stack pointer to store the LNK value
(which is also guarded by the compiler change). As this is conterproductive (the trap
handler should be able to use the extra 1KB memory), a new procedure `Oberon.DisarmTrap`
is implemented that is called during module initialization and scans the code of the
trap procedure for the newly injected trap. That trap instruction is replaced by a no-op
trap instruction (BLNO).

Installation
------------

- Apply [`StackOverflowProtector.patch`](StackOverflowProtector.patch) to `Modules.Mod`,
  `Oberon.Mod`, `System.Mod` and `ORG.Mod`

- Compile Modules.Mod and rebuild the inner core:

      ORP.Compile Modules.Mod ~
      ORL.Link Modules ~
      ORL.Load Modules.bin ~

- Compile the other patched modules:

    ORP.Compile Oberon.Mod System.Mod ~
    ORP.Compile ORG.Mod ~

- Restart the system.
