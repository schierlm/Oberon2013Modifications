MODULE PixelizrObjects;
  IMPORT SYSTEM, Graphics, GraphicFrames, PictureTiles, Rectangles, Fills, DisplayGrab;

  (* Extracting references to rarely needed Pixelizr imports, due to a limit of
   16 imports, imposed by the .rsc Object file format *)

  PROCEDURE MakeFill*(col, x, y: INTEGER; F: GraphicFrames.Frame);
    VAR R: Fills.Fill;
  BEGIN
    NEW(R);
    R.col := col; R.x := x; R.y := y; R.w := 16; R.h := 16;
    R.do := Fills.method;
    Graphics.Add(F.graph, R); R.selected := FALSE;
    GraphicFrames.DrawObj(F, R)
  END MakeFill;

  PROCEDURE MakeBorderRectangle*(col: INTEGER; F: GraphicFrames.Frame);
    VAR R: Rectangles.Rectangle;
  BEGIN
    NEW(R); R.col := col;
    R.x := 14; R.y := 14; R.w := 516; R.h := 516;
    R.lw := 2; R.vers := 0; R.do := Rectangles.method;
    Graphics.Add(F.graph, R); R.selected := FALSE;
    GraphicFrames.DrawObj(F, R);
  END MakeBorderRectangle;

  PROCEDURE MakeTile(X, Y: INTEGER; P: PictureTiles.Picture);
    VAR x, y: INTEGER;
  BEGIN P.w := 32; P.h := 32;
    NEW(P.tile); P.tile.next := NIL;
    P.tile.data[0] := 0; P.tile.data[1] := 0;
    P.tile.data[2] := 32; P.tile.data[3] := 32;
    FOR y := 0 TO 31 DO
      FOR x := 0 TO 31 BY 8 DO
        P.tile.data[4 + y * 4 + x DIV 8] := DisplayGrab.GrabPatternRow(X+x, Y+y, 8) MOD 100H;
      END
    END
  END MakeTile;

  PROCEDURE MakePictureTile*(X, Y, RX, RY, col: INTEGER; GF: GraphicFrames.Frame; VAR T: Graphics.Object);
    VAR P: PictureTiles.Picture;
  BEGIN
    NEW(P); P.col := col; T := P;
    P.x := RX; P.y := RY;
    MakeTile(X, Y, P); P.do := PictureTiles.method;
    Graphics.Add(GF.graph, P); P.selected := FALSE;
    GraphicFrames.DrawObj(GF, P);
  END MakePictureTile;

  PROCEDURE GetTileData*(T: Graphics.Object; X, Y: INTEGER) : BYTE;
    VAR P: PictureTiles.Picture;
  BEGIN P := T(PictureTiles.Picture);
  RETURN P.tile.data[4 + Y * 4 + X DIV 8]
  END GetTileData;

  PROCEDURE UpdatePictureTile*(x, y: INTEGER; T: Graphics.Object);
  VAR P: PictureTiles.Picture;
    X, Y, i: INTEGER;
    s: SET;
  BEGIN P := T(PictureTiles.Picture);
    FOR X := 0 TO 31 DO
      FOR Y := 0 TO 31 DO
        i := P.tile.data[4 + Y * 4 + X DIV 8];
        s := SYSTEM.VAL(SET, i);
        IF DisplayGrab.GrabDot(X*16+x, Y*16+y) # 0 THEN INCL(s, X MOD 8) ELSE EXCL(s, X MOD 8) END;
        i := SYSTEM.VAL(INTEGER, s);
        P.tile.data[4 + Y * 4 + X DIV 8] := i;
      END
    END
  END UpdatePictureTile;

BEGIN
END PixelizrObjects.
