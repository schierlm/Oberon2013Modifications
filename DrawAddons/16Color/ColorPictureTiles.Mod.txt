MODULE ColorPictureTiles;
  IMPORT SYSTEM, Display, DisplayGrab, Files, Texts, Oberon, Graphics, GraphicFrames;

  TYPE Picture = POINTER TO PictureDesc;
    Tile = POINTER TO TileDesc;

    PictureDesc = RECORD (Graphics.ObjectDesc)
      tile: Tile;
    END;

    TileDesc = RECORD
      next: Tile;
      data: ARRAY 244 OF BYTE;
    END;

  VAR method*: Graphics.Method;

  PROCEDURE New*;
    VAR p: Picture;
  BEGIN NEW(p); p.do := method; Graphics.New(p)
  END New;

  PROCEDURE Copy(src, dst: Graphics.Object);
  BEGIN dst.x := src.x; dst.y := src.y; dst.w := src.w; dst.h := src.h; dst.col := src.col;
  dst(Picture).tile := src(Picture).tile
  END Copy;

  PROCEDURE mark(f: GraphicFrames.Frame; col, x, y: INTEGER);
  BEGIN GraphicFrames.ReplConst(f, col, x+1, y+1, 4, 4, Display.invert)
  END mark;

  PROCEDURE Draw(obj: Graphics.Object; VAR M: Graphics.Msg);
    VAR x, y, w, h: INTEGER; f: GraphicFrames.Frame;

    PROCEDURE draw(f: GraphicFrames.Frame; x, y, w, h: INTEGER; tile: Tile);
    VAR xx, yy: INTEGER;
    BEGIN
      GraphicFrames.ReplConst(f, Display.black, x, y, w, h, Display.replace);
      WHILE tile # NIL DO
        xx := x + tile.data[0]*8; yy := y + tile.data[1]*60;
        IF (xx > f.X) & (xx + tile.data[2] <= f.X1) & (yy > f.Y) & (yy + tile.data[3] <= f.Y1) THEN
          DisplayGrab.CopyColorPattern(SYSTEM.ADR(tile.data[2]), xx, yy)
        END;
        tile := tile.next;
      END
    END draw;

  BEGIN
    CASE M OF GraphicFrames.DrawMsg:
      x := obj.x + M.x; y := obj.y + M.y; w := obj.w; h := obj.h; f := M.f;
      IF (x < f.X1) & (x+w > f.X) & (y < f.Y1) & (y+h > f.Y) THEN
        IF M.mode = 0 THEN
          draw(f, x, y, w, h, obj(Picture).tile);
          IF obj.selected THEN mark(f, Display.black, x, y) END
        ELSIF M.mode = 1 THEN mark(f, Display.white, x, y)  (*normal -> selected*)
        ELSIF M.mode = 2 THEN mark(f, Display.black, x, y)  (*selected -> normal*)
        ELSIF M.mode = 3 THEN GraphicFrames.ReplConst(f, Display.black, x, y, w, h, Display.replace)  (*erase*)
        END
      END
    END
  END Draw;

  PROCEDURE Selectable(obj: Graphics.Object; x, y: INTEGER): BOOLEAN;
  BEGIN
    RETURN (obj.x <= x) & (x <= obj.x + 4) & (obj.y <= y) & (y <= obj.y + 4)
  END Selectable;

  PROCEDURE Change(obj: Graphics.Object; VAR M: Graphics.Msg);
    VAR x0, y0, x1, y1, dx, dy: INTEGER; k: SET;
  BEGIN
  END Change;

  PROCEDURE Read(obj: Graphics.Object; VAR R: Files.Rider; VAR C: Graphics.Context);
  VAR curr, prev: Tile;
    i, len: INTEGER;
  BEGIN NEW(curr); obj(Picture).tile := curr; prev := NIL;
    REPEAT
      len := 4; i := 0;
      WHILE i < len DO
        Files.ReadByte(R, curr.data[i]); INC(i);
        IF i = 4 THEN len := 4 + (curr.data[2] + 1) DIV 2 * curr.data[3] END
      END;
      IF len # 4 THEN prev := curr; NEW(curr); prev.next := curr END
    UNTIL len = 4;
    prev.next := NIL
  END Read;

  PROCEDURE Write(obj: Graphics.Object; cno: INTEGER; VAR W: Files.Rider; VAR C: Graphics.Context);
  VAR tile: Tile; i, len: INTEGER;
  BEGIN Graphics.WriteObj(W, cno, obj);
    tile := obj(Picture).tile;
    WHILE tile # NIL DO
      len := 4 + (tile.data[2] + 1) DIV 2 * tile.data[3];
      FOR i := 0 TO len - 1 DO Files.WriteByte(W, tile.data[i]) END;
      tile := tile.next;
    END;
    Files.WriteInt(W, 0)
  END Write;

  PROCEDURE ReadShort(VAR R: Files.Rider; VAR short: INTEGER);
    VAR b0, b1: BYTE;
  BEGIN
    Files.ReadByte(R, b0); Files.ReadByte(R, b1); short := b0 + b1 * 100H
  END ReadShort;

  PROCEDURE LoadPicture(F: Files.File; P: Picture);
    VAR x, y, th, toff, toffLT, i: INTEGER;
      b: BYTE;
      run: BOOLEAN;
      curr: Tile;
      R: Files.Rider;
  BEGIN
    Files.Set(R, F, 0);
    ReadShort(R, i);
    ASSERT(i = 0F003H);
    ReadShort(R, P.w);
    ReadShort(R, P.h);
    ReadShort(R, i);
    ASSERT(i = 4); (* depth *)
    FOR y := 0 TO 16 * 3 - 1 BY 2 DO ReadShort(R, i) END; (* palette *)
    i := 0; y := 0; th := 0; P.tile := NIL; (*TODO*) toff := 4; toffLT := 4;
    FOR y := P.h - 1 TO 0 BY -1 DO
      IF th = 0 THEN (* add new tiles *)
        th := y MOD 60 + 1;
        x := (P.w - 1) DIV 8 * 8;
        NEW(curr); curr.next := P.tile; P.tile := curr;
        curr.data[0] := x DIV 8; curr.data[1] := y DIV 60;
        curr.data[2] := P.w - x; curr.data[3] := th;
        WHILE x > 0 DO
          DEC(x, 8); NEW(curr); curr.next := P.tile; P.tile := curr;
          curr.data[0] := x DIV 8; curr.data[1] := y DIV 60;
          curr.data[2] := 8; curr.data[3] := th;
        END;
        ASSERT(toff = 4); ASSERT(toffLT = 4); (*TODO*)
        toff := 4 + 4 * th; toffLT := 4 + ((P.w MOD 8 + 1) DIV 2) * th;
      END;
      DEC(th); DEC(toff, 4); DEC(toffLT, (P.w MOD 8 + 1) DIV 2);
      curr := P.tile;
      FOR x := 0 TO P.w - 1 BY 2 DO
        IF i = 0 THEN
          Files.ReadByte(R, b);
          IF b >= 80H THEN
            i := 101H - b; run := TRUE;
            Files.ReadByte(R, b)
          ELSE
            i := b + 1; run := FALSE
          END
        END;
        DEC(i);
        IF ~run THEN Files.ReadByte(R, b) END;
        IF curr.data[2] = 8 THEN
          curr.data[toff + x DIV 2 MOD 4] := b
        ELSE
          curr.data[toffLT + x DIV 2 MOD 4] := b
        END;
        IF x DIV 2 MOD 4 = 3 THEN curr := curr.next END
      END
    END
  END LoadPicture;

  PROCEDURE MakePicture*;  (*command*)
    VAR beg, end, t: INTEGER;
      S: Texts.Scanner;
      G: GraphicFrames.Frame;
      text: Texts.Text;
      P: Picture;
      F: Files.File;
  BEGIN G := GraphicFrames.Focus();
    Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    IF (S.class = Texts.Char) & (S.c = "^") THEN
      Oberon.GetSelection(text, beg, end, t);
      IF t >= 0 THEN Texts.OpenScanner(S, text, beg); Texts.Scan(S) END
    END;
    IF (S.class = Texts.Name) & (G # NIL) & (G.marked) THEN
      GraphicFrames.Deselect(G);
      NEW(P); P.col := Oberon.CurCol;
      F := Files.Old(S.s);
      LoadPicture(F, P);
      Files.Close(F);
      P.x := G.mark.x - G.x; P.y := G.mark.y - G.y;
      P.do := method;
      Graphics.Add(G.graph, P);
      GraphicFrames.Defocus(G); GraphicFrames.DrawObj(G, P)
    END
  END MakePicture;

  PROCEDURE LoadPalette*;  (*command*)
    VAR beg, end, t, val, col: INTEGER;
      b0, b1, b2: BYTE;
      S: Texts.Scanner;
      text: Texts.Text;
      F: Files.File;
      R: Files.Rider;
  BEGIN
    Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    IF (S.class = Texts.Char) & (S.c = "^") THEN
      Oberon.GetSelection(text, beg, end, t);
      IF t >= 0 THEN Texts.OpenScanner(S, text, beg); Texts.Scan(S) END
    END;
    IF S.class = Texts.Name THEN
      F := Files.Old(S.s);
      Files.Set(R, F, 0);
      ReadShort(R, val);
      ASSERT(val = 0F003H);
      ReadShort(R, val); (* width *)
      ReadShort(R, val); (* height *)
      ReadShort(R, val); ASSERT(val = 4); (* depth *)
      FOR col := 0 TO 15 DO
        Files.ReadByte(R, b0); Files.ReadByte(R, b1); Files.ReadByte(R, b1);  val := b0 + b1 * 100H + b2 * 10000H;
        DisplayGrab.SetPalette(col, val)
      END;
      Files.Close(F)
    END
  END LoadPalette;

BEGIN NEW(method);
  method.module := "ColorPictureTiles"; method.allocator := "New";
  method.new := New; method.copy := Copy; method.draw := Draw;
  method.selectable := Selectable; method.change := Change;
  method.read := Read; method.write := Write
END ColorPictureTiles.
