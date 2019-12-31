RescueSystem - Boot into secondary inner core in case main one is unable to boot

Description
-----------

When you work on the Oberon system a log (including changing symbol files), it
happens from time to time that you either introduce a bug or forget to recompile a
dependent module (e.g. the compiler) and therefore your system is unbootable or
unusable. When working in an emulator and you have a recent copy of the filesystem
image, the amount of work lost is limited (you may also spend some time to search
for the recently changed source code files in a hex editor to rescue any work you
did inside the emulator; I for myself mostly write the code outside the emulator
and use `PCLink` to get it in), but it is still a nuisance every time it happens.

Therefore, this set of patches introduces a second "rescue system" on the
filesystem which includes a compiler and `ORL.Mod`. It uses the same filesystem
(so in case you break your filesystem, it won't help you), but uses a different
extension (`.rsc.RS`) for the compiled modules, so it won't interfere with your
existing system, and when you run the compiler from the rescue system, it will
"automagically" compile for the normal system so you can easily fix your errors
and recompile. System.Tool is loaded from `System.Tool.RS` and thanks to
[`Fonts.Embedded.Mod`](../MinimalFonts/README.md), no font files are required
in the filesystem; therefore as long as the filesystem is not corrupted and you
do not touch `*.RS` files, the rescue system will be able to boot.

To enter the rescue system, just restart the system after a failed boot. A
boot is considered failed if `Oberon.Call()` is never invoked. As this can only
happen interactively, you can also enter the rescue system by simply restarting
the system before you click anything. At the next restart, the normal system will
be booted again so you can check if you were able to fix your system, and if
required enter the rescue system again.

Note that setting up the rescue system does not only require compiling several
new inner cores, it also requires that you mvoe the filesystem. This can be done
from within the system, but the chance of catastrophic data loss is high in case
anything goes wrong.


Disk layout after installing the rescue system
----------------------------------------------

The (1K) sector at `FSOffset+4` will only contain the filesystem magic `8D A3 1E 9B` so
that the image is detected as an Oberon filesystem by the emulator. The rest of this
sector is filled with zeroes.

The next two sectors are loaded to memory by the boot loader in ROM, and contain a
"rescue system boot loader" (see next section) which is responsible to decide whether
to load the rescue system or the normal system.

The following up to 61 sectors contain the inner core of the rescue system.

After that (64 KB from the original FS offset) the "real" filesystem will be located,
starting with the Directory Root sector, followed by the inner core of the normal system.

Rescue system loader boot process
---------------------------------

The rescue system loader is initally loaded to 0H by the boot loader.

* 00000000: Jump instruction to jump to machine code (`E7000006`)
* 00000004: Toggle value, `00000000` for normal boot, `00000001` for recue system boot
* 00000008: Unused (00000000)
* 0000000C: Memory limit (written by the boot loader)
* 00000010: Length of the rescue system loader in bytes (00000800)
* 00000014: Unused (00000000)
* 00000018: Heap start (written by the boot loader)
* 0000001C: Start of machine code

On first invocation by the boot loader, it will then perform the following actions
- Flip the toggle value
- Write its first sector back to disk
- Copy itself to 20000H (128 KB)
- Modify the jump instruction to `E7008006` so that next boot will jump into the copy
- Exit

On second invocation (now at 20000H) it will instead perform the following actions
- Depending of the value of the toggle value, either load the normal inner core
  (located at `FSoffset + RSoffset + 4`), or the rescue core (located at `FSoffset + 4 + 4`).
- Copy the value of `MemLim` and `stackOrg` from the copy of the recue loader into the inner core
- Exit


Installation
------------

- Push `RescueSystemTool.Mod`, `RescueSystemLoader.Mod`, `System.Tool.RS` to your Oberon system. (Note that
  `RescueSystemLoader.Mod` contains a copy of the `Kernel.FSoffset` constant, so in case your Kernel uses a
  different filesystem offset, update the copy in `RescueSystemLoader.Mod`, too.)

- Also push `Fonts.Embedded.Mod` from [MinimalFonts](../MinimalFonts/README.md) to your Oberon system.

- Compile the new modules:

      ORP.Compile RescueSystemTool.Mod/s RescueSystemLoader.Mod/s ~

- Create copies of `Modules.Mod` and `System.Mod` which are used inside the rescue system.

      System.CopyFiles Modules.Mod => Modules.RS.Mod
        System.Mod => System.RS.Mod ~

- Edit `Kernel.Mod` to add `80H` to `CONST FSOffset`. Also make the required changes to `Modules.RS.Mod`, `System.RS.Mod` and `Oberon.Mod`.
  Do not compile `Oberon.Mod` yet, as it should not get into the rescue system but only into the "normal" system.
  See [RescueSystem.patch](./RescueSystem.patch) or below:

```diff
--- 1/Kernel.Mod.txt
+++ 2/Kernel.Mod.txt
@@ -2,7 +2,7 @@
   IMPORT SYSTEM;
   CONST SectorLength* = 1024;
     timer = -64;
-    FSoffset = 80000H; (*256MB in 512-byte blocks*)
+    FSoffset = 80080H; (*256MB in 512-byte blocks*)
     mapsize = 10000H; (*1K sectors, 64MB*)

   TYPE Sector* = ARRAY SectorLength OF BYTE;
--- 1/Modules.RS.Mod.txt
+++ 2/Modules.RS.Mod.txt
@@ -23,7 +23,8 @@
       filename: ModuleName;
   BEGIN i := 0;
     WHILE name[i] # 0X DO filename[i] := name[i]; INC(i) END ;
-    filename[i] := "."; filename[i+1] := "r"; filename[i+2] := "s"; filename[i+3] := "c"; filename[i+4] := 0X;
+    filename[i] := "."; filename[i+1] := "r"; filename[i+2] := "s"; filename[i+3] := "c";
+    filename[i+4] := "."; filename[i+5] := "R"; filename[i+6] := "S"; filename[i+7] := 0X;
     RETURN Files.Old(filename)
   END ThisFile;

--- 1/System.RS.Mod.txt
+++ 2/System.RS.Mod.txt
@@ -372,8 +372,8 @@
     main := TextFrames.NewText(Oberon.Log, 0);
     logV := MenuViewers.New(menu, main, TextFrames.menuH, X, Y);
     Oberon.AllocateSystemViewer(0, X, Y);
-    menu := TextFrames.NewMenu("System.Tool", StandardMenu);
-    main := TextFrames.NewText(TextFrames.Text("System.Tool"), 0);
+    menu := TextFrames.NewMenu("System.Tool.RS", StandardMenu);
+    main := TextFrames.NewText(TextFrames.Text("System.Tool.RS"), 0);
     toolV := MenuViewers.New(menu, main, TextFrames.menuH, X, Y)
   END OpenViewers;

--- 1/Oberon.Mod.txt
+++ 2/Oberon.Mod.txt
@@ -68,6 +68,7 @@
     DW, DH, CL: INTEGER;
     ActCnt: INTEGER; (*action count for GC*)
     Mod: Modules.Module;
+    CommandsExecuted: BOOLEAN;

   (*user identification*)

@@ -276,12 +277,18 @@
   PROCEDURE SetPar*(F: Display.Frame; T: Texts.Text; pos: LONGINT);
   BEGIN Par.vwr := Viewers.This(F.X, F.Y); Par.frame := F; Par.text := T; Par.pos := pos
   END SetPar;
+
+  PROCEDURE DisarmRescueSystem;
+  VAR sec: Kernel.Sector;
+  BEGIN Kernel.GetSector(-62 * 29, sec); sec[4] := 0; Kernel.PutSector(-62 * 29, sec)
+  END DisarmRescueSystem;

   PROCEDURE Call* (name: ARRAY OF CHAR; VAR res: INTEGER);
     VAR mod: Modules.Module; P: Modules.Command;
       i, j: INTEGER; ch: CHAR;
       Mname, Cname: ARRAY 32 OF CHAR;
   BEGIN i := 0; ch := name[0];
+    IF ~CommandsExecuted THEN DisarmRescueSystem; CommandsExecuted := TRUE END;
     WHILE (ch # ".") & (ch # 0X) DO Mname[i] := ch; INC(i); ch := name[i] END ;
     IF ch = "." THEN
       Mname[i] := 0X; INC(i);
```

- Now is the moment when you should make sure that you have a backup of your Oberon system, in case
  it contains any valuable files.

- Compile the new modules and the modified inner core, and load the inner core to the boot area:

      ORP.Compile Kernel.Mod FileDir.Mod Files.Mod Modules.Mod ~
      ORL.Link Modules ~
      ORL.Load Modules.bin ~

- Move the filesystem by 64KB to the end. After this move, both the "original" boot area
  (before the new Directory Root) and the new boot area will contain the same boot loader,
  which is unchanged except the changed filesystem offset. Be patient, this may take a while;
  as it is hard to detect the end of the filesystem, we will assume the maximum size.

      RescueSystemTool.MoveFilesystem

- Restart the system

- Now build `Modules.bin.RS` as well as the `System` and `Fonts` modules for the rescue system.
  After moving those modules away for the rescue system, restore/recompile them as they should
  remain unchanged in the normal system. Then copy all the modules that initially are the same
  in both systems.

      ORP.Compile Modules.RS.Mod Fonts.Embedded.Mod System.RS.Mod ~
      ORL.Link Modules ~

      System.RenameFiles
        Modules.bin => Modules.bin.RS
        Fonts.rsc => Fonts.rsc.RS
        System.rsc => System.rsc.RS ~

      ORP.Compile Modules.Mod Fonts.Mod System.Mod Oberon.Mod ~
      ORL.Link Modules ~

      System.CopyFiles
        Input.rsc => Input.rsc.RS
        Display.rsc => Display.rsc.RS
        Viewers.rsc => Viewers.rsc.RS
        Texts.rsc => Texts.rsc.RS
        Oberon.rsc => Oberon.rsc.RS
        MenuViewers.rsc => MenuViewers.rsc.RS
        TextFrames.rsc => TextFrames.rsc.RS
        Edit.rsc => Edit.rsc.RS
        PCLink1.rsc => PCLink1.rsc.RS
        Clipboard.rsc => Clipboard.rsc.RS
        ORS.rsc => ORS.rsc.RS
        ORB.rsc => ORB.rsc.RS
        ORG.rsc => ORG.rsc.RS
        ORP.rsc => ORP.rsc.RS
        ORL.rsc => ORL.rsc.RS ~

- You may copy other files if you want to use them in the rescue system.
  (While the rescue system uses the same filesystem, it can only load modules whose name
  end with `.rsc.RS`).

- Now load the rescue system into the boot area (before the Directory Root):

      RescueSystemTool.LoadRescue

- You may now restart your system and test the rescue system.

- If you want to, you can clean up unneccessary files:

      System.DeleteFiles
        RescueSystemTool.rsc RescueSystemLoader.rsc Modules.bin.RS
        RescueSystemTool.Mod RescueSystemLoader.Mod Modules.bin
        Fonts.Embedded.Mod Modules.RS.Mod System.RS.Mod ~
