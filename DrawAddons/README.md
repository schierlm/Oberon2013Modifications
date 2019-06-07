DrawAddons - More features for Oberon Draw

Description
-----------

Chapter 13.2.7 of the [Project Oberon book](http://www.inf.ethz.ch/personal/wirth/ProjectOberon/PO.Applications.pdf)
refers to a module `Splines.Mod`, which is not included in Project Oberon, but was
included in older versions of Oberon. So you will find a ported version here.

Also, other oberon systems have support for displaying `.Pict` files (bitmap graphics).
The `PictureTiles.Mod` module allows to embed bitmap tiles from `.Pict` files into
your graphics. (This is mainly intended so you can view the graphics; while saving
such drawings is supported, the bitmap data of the tiles is stored in uncompressed
form, unlike the `.Pict` format which stores them in RLE-compressed format.) Prefix
a filename with `!` to invert the picture.

Now that more Graphics classes are available, you will occasionally run into TRAPs
as the number of classes that can be simultaneously loaded is limited to 6. Therefore,
let's patch that too.

Installation
------------

- In case you want to use more than 6 classes at a time, [patch `Graphics.Mod`](MoreClasses.patch):

```diff
--- 1/Graphics.Mod.txt
+++ 2/Graphics.Mod.txt
@@ -57,7 +57,7 @@
         nofonts, noflibs, nofclasses: INTEGER;
         font: ARRAY 10 OF Fonts.Font;
         lib: ARRAY 4 OF Library;
-        class: ARRAY 6 OF Modules.Command
+        class: ARRAY 16 OF Modules.Command
       END;

     MethodDesc* = RECORD
```

- Push the new modules, tool and/or picture files.

- Recompile the existing modules:

      ORP.Compile Graphics.Mod/s GraphicsFrames.Mod/s Rectangles.Mod/s Curves.Mod/s ~
      ORP.Compile Draw.Mod/s MacroTool.Mod/s ~

- Compile the new modules:

      ORP.Compile Splines.Mod/s PictureTiles.Mod/s ~

- Use the commands in [`DrawAddons.Tool`](DrawAddons.Tool.txt).