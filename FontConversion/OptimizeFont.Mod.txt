MODULE OptimizeFont;
  IMPORT Files, Texts, Oberon;

  CONST FontFileId = 0DBH;

  PROCEDURE ReadInt16(VAR R: Files.Rider; VAR v: INTEGER);
    VAR b0, b1: BYTE;
  BEGIN Files.ReadByte(R, b0); Files.ReadByte(R, b1); v := b1 * 100H + b0;
  END ReadInt16;

  PROCEDURE WriteInt16(VAR R: Files.Rider; v: INTEGER);
  BEGIN Files.WriteByte(R, v MOD 100H); Files.WriteByte(R, v DIV 100H);
  END WriteInt16;

  PROCEDURE CopyBytes(VAR RR, RW: Files.Rider; count: INTEGER);
    VAR b: BYTE; i: INTEGER;
  BEGIN
    FOR i := 0 TO count - 1 DO
      Files.ReadByte(RR, b);
      Files.WriteByte(RW, b)
    END
  END CopyBytes;

  PROCEDURE OptimizeGlyph(VAR glyph: ARRAY OF BYTE; VAR x, y, w, h: INTEGER);
  VAR i, j, offs, mask, ww: INTEGER; empty, carry, carry2: BOOLEAN;
  BEGIN ww := (w + 7) DIV 8;
    IF w MOD 8 # 0 THEN (* zero excess bits *)
      mask := 1; FOR i := 0 TO w MOD 8 DO mask := mask * 2 END;
      FOR i := 0 TO h - 1 DO
        offs := (i + 1) * ww - 1;
        glyph[offs] := glyph[offs] MOD mask
      END
    END;
    i := h - 1;
    WHILE i >= 0 DO (* trim top (high y values) *)
      empty := TRUE; j := ww - 1;
      WHILE empty & (j >= 0) DO
        empty := (glyph[i * ww + j] = 0); DEC(j);
      END;
      IF empty THEN
        DEC(i); DEC(h)
      ELSE
        i := -1
      END
    END;
    i := h;
    WHILE i > 0 DO (* trim bottom (low y values) *)
      empty := TRUE; j := ww - 1;
      WHILE empty & (j >= 0) DO
        empty := (glyph[j] = 0); DEC(j);
      END;
      IF empty THEN
        DEC(h); INC(y);
        FOR j := 0 TO ww * h - 1 DO glyph[j] := glyph[j + ww] END;
        i := h
      ELSE
        i := -1
      END
    END;
    i := w - 1;
    WHILE i >= 0 DO (* trim right *)
      mask := 1; FOR j := 1 TO i MOD 8 DO mask := mask * 2 END;
      empty := TRUE; j := h - 1;
      WHILE empty & (j >= 0) DO
        empty := (glyph[j * ww + i DIV 8] DIV mask MOD 2 = 0); DEC(j);
      END;
      IF empty THEN
        DEC(i); DEC(w)
      ELSE
        i := -1
      END
    END;
    i := w;
    WHILE i > 0 DO (* trim left *)
      empty := TRUE; j := h - 1;
      WHILE empty & (j >= 0) DO
        empty := (glyph[j * ww] = 0); DEC(j);
      END;
      IF empty THEN
        DEC(w); INC(x); carry := FALSE;
        FOR j := ww * h - 1 TO 0 DO
          carry2 := glyph[j] MOD 2 # 0;
          glyph[j] := glyph[j] DIV 2 + ORD(carry) * 80H;
          carry := carry2;
        END;
        i := w
      ELSE
        i := -1
      END
    END;
    mask := (w + 7) DIV 8;
    IF ww # mask THEN
      ASSERT(mask < ww);
      FOR i := 1 TO h - 1 DO
        FOR j := 0 TO mask - 1 DO
          glyph[i * mask + j] := glyph[i * ww + j];
        END
      END
    END
  END OptimizeGlyph;

  PROCEDURE Optimize*;
    VAR i, j, x, y, w, h, beg, end, NofRuns, NofGlyphs: INTEGER;
      b: BYTE;
      S: Texts.Scanner;
      FR, FW: Files.File;
      RR, RR2, RW, RW2: Files.Rider;
      glyph: ARRAY 256 OF BYTE;
  BEGIN
    Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S); b := 0;
    IF S.class = Texts.Name THEN
      FR := Files.Old(S.s); Files.Set(RR, FR, 0); Files.ReadByte(RR, b);
    END;
    IF b = FontFileId THEN
      FW := Files.New(S.s); Files.Set(RW, FW, 0); Files.WriteByte(RW, b);
      CopyBytes(RR, RW, 13); (*abstraction, family, variant; height, minX, maxX, minY, maxY *)
      ReadInt16(RR, NofRuns); WriteInt16(RW, NofRuns);
      NofGlyphs := 0;
      FOR i := 1 TO NofRuns DO
        ReadInt16(RR, beg); WriteInt16(RW, beg);
        ReadInt16(RR, end); WriteInt16(RW, end);
        INC(NofGlyphs, end - beg)
      END;
      Files.Set(RR2, FR, Files.Pos(RR));
      Files.Set(RW2, FW, Files.Pos(RW));
      CopyBytes(RR, RW, NofGlyphs * 10); (* will be overwritten later *)
      FOR i := 1 TO NofGlyphs DO
        ReadInt16(RR2, x); WriteInt16(RW2, x); (*dx*)
        ReadInt16(RR2, x); ReadInt16(RR2, y); ReadInt16(RR2, w); ReadInt16(RR2, h);
        FOR j := 0 TO ((w + 7) DIV 8) * h - 1 DO Files.ReadByte(RR, glyph[j]) END;
        OptimizeGlyph(glyph, x, y, w, h);
        WriteInt16(RW2, x); WriteInt16(RW2, y); WriteInt16(RW2, w); WriteInt16(RW2, h);
        FOR j := 0 TO ((w + 7) DIV 8) * h - 1 DO Files.WriteByte(RW, glyph[j]) END
      END;
      Files.Register(FW)
    END;
    Files.Close(FR)
  END Optimize;
END OptimizeFont.
