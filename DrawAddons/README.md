DrawAddons - More features for Oberon Draw

Description
-----------

Chapter 13.2.7 of the [Project Oberon book](http://www.inf.ethz.ch/personal/wirth/ProjectOberon/PO.Applications.pdf)
refers to a module `Splines.Mod`, which is not included in Project Oberon, but was
included in older versions of Oberon. So you will find a ported version here, as well
as a version of `Bezier.Mod`.

Also, other oberon systems have support for displaying `.Pict` files (bitmap graphics).
The `PictureTiles.Mod` module allows to embed bitmap tiles from `.Pict` files into
your graphics. (This is mainly intended so you can view the graphics; while saving
such drawings is supported, the bitmap data of the tiles is stored in uncompressed
form, unlike the `.Pict` format which stores them in RLE-compressed format.) Prefix
a filename with `!` to invert the picture.

One drawing "primitive" that is missing from Draw is flood fill, implemented in
`Fills.Mod`. Therefore, an additional module is required to "grab" contents on the
screen, which is called `DisplayGrab.Mod` and may need adjusting if you are using a
modified `Display.Mod` (There is a second version of this module available in `16Colors`
directory, in case your display is 16 colors).

And since `PictureTiles` only allows loading of `.Pict` files, there is a module
called `PictureGrab`, which can be used to take (partial) screenshots and save them
as `.Pict` files.

The last new module is `Pixelizr`, which is a very simple zoomed pixel editor:
Point it to a 32x32 area inside a drawing, and it will open a second drawing
that provides a huge version of it. By default, left and right mouse button are
modified to set and clear "pixels", but you can "disable" that override and use
normal drawing functions as well. "Pixelizr.Apply" will create a picture tile
from the result and add it back to the original drawing.

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

      ORP.Compile Graphics.Mod/s GraphicFrames.Mod/s Rectangles.Mod/s Curves.Mod/s ~
      ORP.Compile Draw.Mod/s MacroTool.Mod/s ~

- Compile the new modules:

      ORP.Compile Splines.Mod/s Bezier.Mod/s PictureTiles.Mod/s ~
      ORP.Compile DisplayGrab.Mod/s Fills.Mod/s ~
      ORP.Compile PictureGrab.Mod/s ~
      ORP.Compile PixelizrObjects.Mod/s Pixelizr.Mod/s ~

- In case of a 16 color screen, you can also grab and display 16 color `.Pict` files:

      ORP.Compile ColorPictureTiles.Mod/s ~
      ORP.Compile ColorPictureGrab.Mod/s ~

- Use the commands in [`DrawAddons.Tool`](DrawAddons.Tool.txt).
