MODULE Fills;
  IMPORT Display, DisplayGrab, Files, Oberon, Graphics, GraphicFrames;

  TYPE Fill* = POINTER TO FillDesc;
    FillDesc* = RECORD (Graphics.ObjectDesc) END;

    Segment = POINTER TO SegmentDesc;
    SegmentDesc = RECORD
      x1, x2, y: INTEGER;
      dir: BYTE; (* 2: above the previous segment, 1: below the previous segment, 0: no previous segment *)
      left, right: BOOLEAN;
      next: Segment;
    END;

  VAR method*: Graphics.Method;
    segstack, freeSegments: Segment;

  (* scanline fill based on http://www.adammil.net/blog/v126_A_More_Efficient_Flood_Fill.html *)

  PROCEDURE ScanlineAddSegment(newcol, x1, x2, y: INTEGER; dir: BYTE; left, right: BOOLEAN);
  VAR seg: Segment;
  BEGIN
    IF freeSegments # NIL THEN
      seg := freeSegments; freeSegments := seg.next
    ELSE
      NEW(seg)
    END;
    seg.x1 := x1; seg.x2 := x2; seg.y := y;
    seg.dir := dir; seg.left := left; seg.right := right;
    seg.next := segstack;
    segstack := seg;
    Display.ReplConst(newcol, x1, y, x2-x1, 1, Display.replace)
  END ScanlineAddSegment;

  PROCEDURE ScanlineAdd(oldcol, newcol, x1, x2, y, ix1, ix2: INTEGER; dir: BYTE; sameDir: BOOLEAN);
  VAR sx, x: INTEGER;
  BEGIN
    sx := -1; x := x1;
    WHILE x < x2 DO
      IF (sameDir OR (x < ix1) OR (x >= ix2)) & (DisplayGrab.GrabDot(x, y) = oldcol) THEN
        IF sx < 0 THEN sx := x END
      ELSIF sx >= 0 THEN
        ScanlineAddSegment(newcol, sx, x, y, dir, sx = x1, FALSE);
        sx := -1
      END;
      IF (~sameDir) & (x >= ix1) & (x < ix2) THEN x := ix2 ELSE INC(x) END
    END;
    IF sx >= 0 THEN ScanlineAddSegment(newcol, sx, x, y, dir, sx = x1, TRUE) END;
  END ScanlineAdd;

  PROCEDURE ScanlineFill(newcol, x, y: INTEGER);
  VAR col, oldcol, x1, x2: INTEGER;
    seg: Segment;
  BEGIN
    oldcol := DisplayGrab.GrabDot(x, y);
    Display.Dot(newcol, x, y, Display.replace);
    segstack := NIL; freeSegments := NIL;
    ScanlineAddSegment(newcol, x, x+1, y, 0, TRUE, TRUE);
    WHILE segstack # NIL DO
      seg := segstack; segstack := seg.next; x1 := seg.x1; x2 := seg.x2;
      WHILE seg.left & (x1 > 0) & (DisplayGrab.GrabDot(x1-1, seg.y) = oldcol) DO DEC(x1) END;
      WHILE seg.right & (x2 < Display.Width) & (DisplayGrab.GrabDot(x2, seg.y) = oldcol) DO INC(x2) END;
      IF x1 # seg.x1 THEN Display.ReplConst(newcol, x1, seg.y, seg.x1 - x1, 1, Display.replace) END;
      IF x2 # seg.x2 THEN Display.ReplConst(newcol, seg.x2, seg.y, x2 - seg.x2, 1, Display.replace) END;
      DEC(seg.x1); INC(seg.x2);
      IF seg.y > 0 THEN ScanlineAdd(oldcol, newcol, x1, x2, seg.y - 1, seg.x1, seg.x2, 2, seg.dir = 2) END;
      IF seg.y < Display.Height - 1 THEN ScanlineAdd(oldcol, newcol, x1, x2, seg.y + 1, seg.x1, seg.x2, 1, seg.dir = 1) END;
      seg.next := freeSegments; freeSegments := seg
    END;
    freeSegments := NIL
  END ScanlineFill;

  (* end of scanline fill *)

  PROCEDURE New*;
    VAR f: Fill;
  BEGIN NEW(f); f.do := method; Graphics.New(f)
  END New;

  PROCEDURE Copy(src, dst: Graphics.Object);
  BEGIN dst.x := src.x; dst.y := src.y; dst.w := src.w; dst.h := src.h; dst.col := src.col
  END Copy;

  PROCEDURE mark(f: GraphicFrames.Frame; col, x, y: INTEGER);
  BEGIN GraphicFrames.ReplConst(f, col, x+1, y+1, 4, 4, 0)
  END mark;

  PROCEDURE Draw(obj: Graphics.Object; VAR M: Graphics.Msg);
    VAR x, y, w, h, col, mcol: INTEGER; f: GraphicFrames.Frame;

    PROCEDURE draw(f: GraphicFrames.Frame; col, x, y, w, h: INTEGER);
    VAR oldcol: INTEGER;
    BEGIN
      IF (w = 0) & (h = 0) THEN
        ScanlineFill(col, x, y)
      ELSE
        GraphicFrames.ReplConst(f, col, x, y, w, h, Display.replace)
      END;
    END draw;

  BEGIN
    CASE M OF GraphicFrames.DrawMsg:
      x := obj.x + M.x; y := obj.y + M.y; w := obj.w; h := obj.h; f := M.f;
      IF (x < f.X1) & (x+w > f.X) & (y < f.Y1) & (y+h > f.Y) THEN
        IF M.col = Display.black THEN col := obj.col ELSE col := M.col END ;
        IF col = Display.black THEN mcol := Display.white ELSE mcol := Display.black END;
        IF (w = 0) & (h = 0) THEN
          IF M.mode = 0 THEN draw(f, col, x, y, w, h) END
        ELSIF M.mode = 0 THEN
          draw(f, col, x, y, w, h);
          IF obj.selected & ((w # 0) OR (h # 0)) THEN mark(f, mcol, x, y) END
        ELSIF M.mode = 1 THEN mark(f, mcol, x, y)  (*normal -> selected*)
        ELSIF M.mode = 2 THEN mark(f, col, x, y)  (*selected -> normal*)
        ELSIF M.mode = 3 THEN draw(f, Display.black, x, y, w, h); mark(f, Display.black, x, y)  (*erase*)
        END
      END
    END
  END Draw;

  PROCEDURE Selectable(obj: Graphics.Object; x, y: INTEGER): BOOLEAN;
  BEGIN
    RETURN (obj.x <= x) & (x <= obj.x + 4) & (obj.y <= y) & (y <= obj.y + 4) & ((obj.w # 0) OR (obj.h # 0))
  END Selectable;

  PROCEDURE Change(obj: Graphics.Object; VAR M: Graphics.Msg);
    VAR x0, y0, x1, y1, dx, dy: INTEGER; k: SET;
  BEGIN
    CASE M OF
    Graphics.ColorMsg: obj.col := M.col
    END
  END Change;

  PROCEDURE Read(obj: Graphics.Object; VAR R: Files.Rider; VAR C: Graphics.Context);
  BEGIN
  END Read;

  PROCEDURE Write(obj: Graphics.Object; cno: INTEGER; VAR W: Files.Rider; VAR C: Graphics.Context);
  BEGIN Graphics.WriteObj(W, cno, obj)
  END Write;

  PROCEDURE MakeFilledRectangle*;  (*command*)
    VAR x0, x1, y0, y1: INTEGER;
      R: Fill;
      G: GraphicFrames.Frame;
  BEGIN G := GraphicFrames.Focus();
    IF (G # NIL) & (G.mark.next # NIL) THEN
      GraphicFrames.Deselect(G);
      x0 := G.mark.x; y0 := G.mark.y; x1 := G.mark.next.x; y1 := G.mark.next.y;
      NEW(R); R.col := Oberon.CurCol;
      R.w := ABS(x1-x0); R.h := ABS(y1-y0);
      IF x1 < x0 THEN x0 := x1 END;
      IF y1 < y0 THEN y0 := y1 END;
      R.x := x0 - G.x; R.y := y0 - G.y;
      R.do := method;
      Graphics.Add(G.graph, R);
      GraphicFrames.Defocus(G); GraphicFrames.DrawObj(G, R)
    END
  END MakeFilledRectangle;

  PROCEDURE MakeFloodFill*; (*command*)
    VAR R: Fill; G: GraphicFrames.Frame;
  BEGIN G := GraphicFrames.Focus();
    IF (G # NIL) & (G.marked) THEN
      GraphicFrames.Deselect(G);
      NEW(R); R.col := Oberon.CurCol;
      R.w := 0; R.h := 0; R.x := G.mark.x - G.x; R.y := G.mark.y - G.y;
      R.do := method;
      Graphics.Add(G.graph, R);
      GraphicFrames.Defocus(G); GraphicFrames.DrawObj(G, R)
    END
  END MakeFloodFill;

BEGIN NEW(method);
  method.module := "Fills"; method.allocator := "New";
  method.new := New; method.copy := Copy; method.draw := Draw;
  method.selectable := Selectable; method.change := Change;
  method.read := Read; method.write := Write
END Fills.
