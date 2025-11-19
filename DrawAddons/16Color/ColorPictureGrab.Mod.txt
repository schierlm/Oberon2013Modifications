MODULE ColorPictureGrab;
  IMPORT DisplayGrab, Files, Texts, Oberon, GraphicFrames;

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
    WriteShort(R, 4); (* depth *)
    FOR xx := 0 TO 15 DO (* palette *)
      DisplayGrab.GetPalette(xx, yy);
      Files.WriteByte(R, yy MOD 100H);
      Files.WriteByte(R, yy DIV 100H MOD 100H);
      Files.WriteByte(R, yy DIV 10000H)
    END;
    xx := x; yy := y + h - 1; lastcount := 0; bufcount := 0;
    WHILE yy >= y DO
      ww := x + w - xx; px := DisplayGrab.GrabDot(xx, yy);
      IF ww > 1 THEN ww := 2; px := px + 10H * DisplayGrab.GrabDot(xx + 1, yy) END;
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
END ColorPictureGrab.
