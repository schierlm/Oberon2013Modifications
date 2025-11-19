MODULE PictureGrab;
  IMPORT DisplayGrab, Files, Input, Texts, Oberon, GraphicFrames;

  PROCEDURE WriteShort(VAR R: Files.Rider; short: INTEGER);
  BEGIN
    Files.WriteByte(R, short MOD 100H); Files.WriteByte(R, short DIV 100H MOD 100H)
  END WriteShort;

  PROCEDURE SavePicture(F: Files.File; x, y, w, h: INTEGER);
  VAR xx, yy, ww, lastcount, bufcount: INTEGER;
    px, lastpx: BYTE;
    buf: ARRAY 128 OF BYTE;
    R: Files.Rider;
  BEGIN
    Files.Set(R, F, 0);
    WriteShort(R, 0F003H);
    WriteShort(R, w);
    WriteShort(R, h);
    WriteShort(R, 1); (* depth *)
    Files.WriteByte(R, 0);Files.WriteByte(R, 0);Files.WriteByte(R, 0);
    Files.WriteByte(R, 0FFH); Files.WriteByte(R, 0FFH); Files.WriteByte(R, 0FFH); (* palette *)
    xx := x; yy := y + h - 1; lastcount := 0; bufcount := 0;
    WHILE yy >= y DO
      ww := x + w - xx; IF ww > 8 THEN ww := 8 END;
      px := DisplayGrab.GrabPatternRow(xx, yy, ww) MOD 100H;
      INC(xx, ww); IF xx = x + w THEN xx := x; DEC(yy) END;
      IF (lastcount = 0) OR (lastpx = px) THEN
        IF bufcount > 0 THEN
          Files.WriteByte(R, bufcount - 1);
          Files.WriteBytes(R, buf, bufcount);
          bufcount := 0
        END;
        INC(lastcount);
        IF lastcount = 128 THEN
          Files.WriteByte(R, 101H - lastcount);
          Files.WriteByte(R, lastpx);
          lastcount := 0
        END
      ELSIF lastcount = 1 THEN
        buf[bufcount] := lastpx;
        INC(bufcount);
        IF bufcount = 128 THEN
          Files.WriteByte(R, bufcount - 1);
          Files.WriteBytes(R, buf, bufcount);
          bufcount := 0
        END
      ELSE
        Files.WriteByte(R, 101H - lastcount);
        Files.WriteByte(R, lastpx);
        lastcount := 1
      END;
      lastpx := px;
    END;
    IF lastcount = 1 THEN
      buf[bufcount] := lastpx;
      INC(bufcount);
    END;
    IF bufcount > 0 THEN
      Files.WriteByte(R, bufcount - 1);
      Files.WriteBytes(R, buf, bufcount);
    END;
    IF lastcount > 1 THEN
      Files.WriteByte(R, 101H - lastcount);
      Files.WriteByte(R, lastpx);
    END;
  END SavePicture;

  PROCEDURE Grab(x, y: INTEGER; VAR S: Texts.Scanner);
    VAR beg, end, t, w, h: INTEGER;
      F: Files.File;
      text: Texts.Text;
  BEGIN
    IF S.class = Texts.Int THEN w := S.i; Texts.Scan(S) ELSE w := 32 END;
    IF S.class = Texts.Int THEN h := S.i; Texts.Scan(S) ELSE h := 32 END;
    IF (S.class = Texts.Char) & (S.c = "^") THEN
      Oberon.GetSelection(text, beg, end, t);
      IF t >= 0 THEN Texts.OpenScanner(S, text, beg); Texts.Scan(S) END
    END;
    IF (S.class = Texts.Name) THEN
      F := Files.New(S.s);
      SavePicture(F, x, y, w, h);
      Files.Register(F)
    END
  END Grab;

  PROCEDURE PrintDraggedRect*;
  VAR W: Texts.Writer;
    k: SET; x1, y1, x2, y2, t: INTEGER;
  BEGIN
    REPEAT Input.Mouse(k, x1, y1);
      Oberon.DrawMouseArrow(x1, y1)
    UNTIL  k # {};
    REPEAT Input.Mouse(k, x2, y2);
      Oberon.DrawMouseArrow(x2, y2)
    UNTIL  k = {};
    Oberon.FadeMouse;
    IF x2 < x1 THEN t := x1; x1 := x2; x2 := t END;
    IF y2 < y1 THEN t := y1; y1 := y2; y2 := t END;
    DEC(x2, x1); DEC(y2, y1);
    Texts.OpenWriter(W);
    Texts.WriteString(W,"Rect: ");
    Texts.WriteInt(W, x1, 11);
    Texts.WriteInt(W, y1, 11);
    Texts.WriteInt(W,  x2, 11);
    Texts.WriteInt(W, y2, 11);
    Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
  END PrintDraggedRect;

  PROCEDURE GrabScreenshot*;  (*command*)
    VAR x, y: INTEGER;
      S: Texts.Scanner;
  BEGIN
    Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    IF S.class = Texts.Int THEN x := S.i; Texts.Scan(S) ELSE x := 0 END;
    IF S.class = Texts.Int THEN y := S.i; Texts.Scan(S) ELSE y := 0 END;
    Grab(x, y, S)
  END GrabScreenshot;

  PROCEDURE GrabPicture*;  (*command*)
    VAR S: Texts.Scanner;
      G: GraphicFrames.Frame;
  BEGIN
    G := GraphicFrames.Focus();
    Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    IF (G # NIL) & (G.marked) THEN
      Grab(G.mark.x, G.mark.y, S)
    END
  END GrabPicture;

BEGIN
END PictureGrab.
