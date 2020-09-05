MODULE GrowFont;
  IMPORT SYSTEM, Files, Texts, Oberon;

  CONST FontFileId = 0DBH;

      (*
         input bit pattern      output bit pattern
               9
             0 1 2              0 1       0 1 2
           a 3 4 5 b            2 3       3 4 5
             6 7 8                        6 7 8
               c
      *)

  TYPE
    CallbackProc = PROCEDURE (in: SET; VAR out: SET);
    LineRec = POINTER TO LineDesc;
    LineDesc = RECORD l: ARRAY 32 OF BYTE END;
    GlyphRec = RECORD w, h: BYTE END;

  VAR
    oldLines: ARRAY 5 OF LineRec;
    newLines: ARRAY 3 OF LineRec;

  PROCEDURE GrabPixel(line, x, idx: INTEGER; VAR set : SET);
    VAR b : INTEGER; s : SET;
  BEGIN
    b := oldLines[line].l[x DIV 8];
    s := SYSTEM.VAL(SET, b);
    IF (x MOD 8) IN s THEN INCL(set, idx) END;
  END GrabPixel;

  PROCEDURE SetPixel(line, x: INTEGER);
    VAR b : INTEGER; s : SET;
  BEGIN
    b := newLines[line].l[x DIV 8];
    s := SYSTEM.VAL(SET, b);
    INCL(s, x MOD 8);
    b := SYSTEM.VAL(INTEGER, s);
    newLines[line].l[x DIV 8] := b;
  END SetPixel;

  PROCEDURE ClearLine(VAR line : LineRec);
  VAR i: INTEGER;
  BEGIN
    FOR i := 0 TO 31 DO line.l[i] := 0 END
  END ClearLine;

  PROCEDURE ScaleLine(factor, width: INTEGER; callback: CallbackProc);
  VAR i, j, x: INTEGER; in, out: SET;
  BEGIN
    FOR i := 0 TO factor - 1 DO ClearLine(newLines[i]) END;
    FOR x := 0 TO width - 1 DO
      in := {};
      FOR i := 0 TO 2 DO
        IF x > 0 THEN GrabPixel(i + 1, x - 1, i * 3, in) END;
        GrabPixel(i + 1, x, i * 3 + 1, in);
        IF x < width - 1 THEN GrabPixel(i + 1, x + 1, i * 3 + 2, in) END
      END;
      GrabPixel(0, x, 9, in); GrabPixel(4, x, 12, in);
      IF x > 1 THEN GrabPixel(3, x-2, 10, in) END;
      IF x < width - 2 THEN GrabPixel(3, x+2, 11, in) END;
      callback(in, out);
      FOR i := 0 TO factor - 1 DO
        FOR j := 0 TO factor - 1 DO
          IF (i * factor + j) IN out THEN SetPixel(i, x * factor + j) END
        END
      END
    END
  END ScaleLine;

  PROCEDURE RdInt16(VAR R: Files.Rider; VAR b0: BYTE);
    VAR b1: BYTE;
  BEGIN Files.ReadByte(R, b0); Files.ReadByte(R, b1)
  END RdInt16;

  PROCEDURE WrInt16(VAR R: Files.Rider; b0: BYTE);
  BEGIN Files.WriteByte(R, b0); Files.WriteByte(R, 0);
  END WrInt16;

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

  PROCEDURE DoScale(factor: INTEGER; callback: CallbackProc);
    VAR i, j, k, w, NofGlyphs, NofRuns: INTEGER;
      b: BYTE;
      FR, FW: Files.File;
      RR, RW: Files.Rider;
      S: Texts.Scanner;
      glyph: ARRAY 512 OF GlyphRec;
      tempLine: LineRec;
  BEGIN
    Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    IF S.class = Texts.Name THEN
      FR := Files.Old(S.s); Files.Set(RR, FR, 0); Files.ReadByte(RR, b); Texts.Scan(S);
    END;
    IF (S.class = Texts.Name) & (b = FontFileId) THEN
      FOR i := 0 TO 4 DO NEW(oldLines[i]) END;
      FOR i := 0 TO factor - 1 DO NEW(newLines[i]) END;
      FW := Files.New(S.s); Files.Set(RW, FW, 0); Files.WriteByte(RW, b);
      CopyBytes(RR, RW, 3); (*abstraction, family, variant *)
      RdInt16(RR, b); WrInt16(RW, b * factor); (*height*)
      RdInt16(RR, b); WrInt16(RW, b * factor); (*minX*)
      RdInt16(RR, b); WrInt16(RW, b * factor); (*maxX*)
      RdInt16(RR, b); WrInt16(RW, b * factor); (*minY*)
      RdInt16(RR, b); WrInt16(RW, b * factor); (*maxY*)
      ReadInt16(RR, NofRuns); WriteInt16(RW, NofRuns);
      NofGlyphs := 0;
      FOR i := 0 TO NofRuns - 1 DO
        ReadInt16(RR, j); ReadInt16(RR, k);
        WriteInt16(RW, j); WriteInt16(RW, k); INC(NofGlyphs, k-j)
      END;
      FOR i := 0 TO NofGlyphs - 1 DO
        RdInt16(RR, b); WrInt16(RW, b * factor); (*dx*)
        RdInt16(RR, b); WrInt16(RW, b * factor); (*x*)
        RdInt16(RR, b); WrInt16(RW, b * factor); (*y*)
        RdInt16(RR, glyph[i].w); WrInt16(RW, glyph[i].w * factor);
        RdInt16(RR, glyph[i].h); WrInt16(RW, glyph[i].h * factor);
      END;
      FOR i := 0 TO NofGlyphs - 1 DO
        w := glyph[i].w;
        ClearLine(oldLines[0]); ClearLine(oldLines[1]);
        Files.ReadBytes(RR, oldLines[2].l, (w + 7) DIV 8);
        IF glyph[i].h = 1 THEN ClearLine(oldLines[3]) ELSE Files.ReadBytes(RR, oldLines[3].l, (w + 7) DIV 8) END;
        FOR j := glyph[i].h TO 1 BY -1 DO
          IF j <= 2 THEN ClearLine(oldLines[4]) ELSE Files.ReadBytes(RR, oldLines[4].l, (w + 7) DIV 8) END;
          ScaleLine(factor, w, callback);
          FOR k := 0 TO factor - 1 DO
            Files.WriteBytes(RW, newLines[k].l, (w * factor + 7) DIV 8)
          END;
          tempLine := oldLines[0];
          oldLines[0] := oldLines[1];
          oldLines[1] := oldLines[2];
          oldLines[2] := oldLines[3];
          oldLines[3] := oldLines[4];
          oldLines[4] := tempLine
        END
      END;
      Files.Register(FW);
    END;
    Files.Close(FR);
    FOR i := 0 TO 4 DO oldLines[i] := NIL END;
    FOR i := 0 TO 2 DO newLines[i] := NIL END
  END DoScale;

  PROCEDURE CallbackX2(in: SET; VAR out: SET);
  BEGIN
    IF 4 IN in THEN out := {0 .. 3} ELSE out := {} END
  END CallbackX2;

  PROCEDURE X2*;
  BEGIN
  DoScale(2, CallbackX2);
  END X2;

  PROCEDURE CallbackX3(in: SET; VAR out: SET);
  BEGIN
    IF 4 IN in THEN out := {0 .. 8} ELSE out := {} END
  END CallbackX3;

  PROCEDURE X3*;
  BEGIN
  DoScale(3, CallbackX3);
  END X3;

  (* Algorithms below are from https://en.wikipedia.org/wiki/Pixel-art_scaling_algorithms
     and https://github.com/libretro/common-shaders *)

  PROCEDURE CopySetBit(in: SET; src: INTEGER; out: SET; dst: INTEGER);
  BEGIN
    IF src IN in THEN INCL(out, dst) ELSE EXCL(out, dst) END
  END CopySetBit;

  PROCEDURE CallbackEPX2(in: SET; VAR out: SET);
  VAR a,b,c,d: INTEGER;
  BEGIN
    IF 4 IN in THEN out := {0 .. 3} ELSE out := {} END;
    a := ORD(1 IN in); b := ORD(5 IN in); c := ORD(3 IN in); d := ORD(7 IN in);
    IF (c = a) & (c # d) & (a # b) THEN CopySetBit(in, 1, out, 0) END;
    IF (a = b) & (a # c) & (b # d) THEN CopySetBit(in, 5, out, 1) END;
    IF (d = c) & (d # b) & (c # a) THEN CopySetBit(in, 3, out, 2) END;
    IF (b = d) & (b # a) & (d # c) THEN CopySetBit(in, 7, out, 3) END;
  END CallbackEPX2;

  PROCEDURE EPX2*;
  BEGIN
  DoScale(2, CallbackEPX2);
  END EPX2;

  PROCEDURE CallbackEPX3(in: SET; VAR out: SET);
  VAR a, b, c, d, e, f, g, h, i: INTEGER;
  BEGIN
    IF 4 IN in THEN out := {0 .. 8} ELSE out := {} END;
    a := ORD(0 IN in); b := ORD(1 IN in); c := ORD(2 IN in);
    d := ORD(3 IN in); e := ORD(4 IN in); f := ORD(5 IN in);
    g := ORD(6 IN in); h := ORD(7 IN in); i := ORD(8 IN in);

    IF (d = b) & (d # h) & (b # f) THEN CopySetBit(in, 3, out, 0) END;
    IF ((d = b) & (d # h) & (b # f) & (e # c)) OR ((b = f) & (b # d) & (f # h) & (e # a)) THEN CopySetBit(in, 1, out, 1) END;
    IF (b = f) & (b # d) & (f # h) THEN CopySetBit(in, 5, out, 2) END;
    IF ((h = d) & (h # f) & (d # b) & (e # a)) OR ((d = b) & (d # h) & (b # f) & (e # g)) THEN CopySetBit(in, 3, out, 3) END;

    IF ((b = f) & (b # d) & (f # h) & (e # i)) OR ((f = h) & (f # b) & (h # d) & (e # c)) THEN CopySetBit(in, 5, out, 5) END;
    IF (h = d) & (h # f) & (d # b) THEN CopySetBit(in, 3, out, 6) END;
    IF ((f = h) & (f # b) & (h # d) & (e # g)) OR ((h = d) & (h # f) & (d # b) & (e # i)) THEN CopySetBit(in, 7, out, 7) END;
    IF (f = h) & (f # b) & (h # d) THEN CopySetBit(in, 5, out, 8) END;
  END CallbackEPX3;

  PROCEDURE EPX3*;
  BEGIN
  DoScale(3, CallbackEPX3);
  END EPX3;


  PROCEDURE CallbackEagle(in: SET; VAR out: SET);
  VAR s,t,u,v,w,x,y,z: INTEGER;
  BEGIN
    IF 4 IN in THEN out := {0 .. 3} ELSE out := {} END;
    s := ORD(0 IN in); t := ORD(1 IN in); u := ORD(2 IN in); v := ORD(3 IN in);
    w := ORD(5 IN in); x := ORD(6 IN in); y := ORD(7 IN in); z := ORD(8 IN in);
    IF (v = s) & (s = t) THEN CopySetBit(in, 0, out, 0) END;
    IF (t = u) & (u = w) THEN CopySetBit(in, 2, out, 1) END;
    IF (v = x) & (x = y) THEN CopySetBit(in, 6, out, 2) END;
    IF (w = z) & (z = y) THEN CopySetBit(in, 8, out, 3) END;
  END CallbackEagle;

  PROCEDURE Eagle*;
  BEGIN
  DoScale(2, CallbackEagle);
  END Eagle;

  PROCEDURE CallbackScale2SFX(in: SET; VAR out: SET);
  VAR a,b,c,d,e,f,g,h,i,j,k,l,m: INTEGER;
    p0, p1, a0, a1: BOOLEAN;
  BEGIN
    a := ORD(0 IN in); b := ORD(1 IN in); c := ORD(2 IN in);
    d := ORD(3 IN in); e := ORD(4 IN in); f := ORD(5 IN in);
    g := ORD(6 IN in); h := ORD(7 IN in); i := ORD(8 IN in);
    j := ORD(9 IN in); k := ORD(10 IN in);
    l := ORD(11 IN in); m := ORD(12 IN in);
    p0 := (b # f) & (d # h);
    p1 := (b # d) & (f # h);
    a0 := (c = e) & (e = g);
    a1 := (a = e) & (e = i);
    IF e # 0 THEN out := {0 .. 3} ELSE out := {} END;
    IF (b = d) & p0 & ((a # e) OR a0 OR (a = j) OR (a = k)) THEN CopySetBit(in, 1, out, 0) END;
    IF (b = f) & p1 & ((c # e) OR a1 OR (c = j) OR (c = l)) THEN CopySetBit(in, 5, out, 1) END;
    IF (d = h) & p1 & ((e # g) OR a1 OR (g = k) OR (g = m)) THEN CopySetBit(in, 3, out, 2) END;
    IF (f = h) & p0 & ((e # i) OR a0 OR (i = l) OR (i = m)) THEN CopySetBit(in, 7, out, 3) END;
  END CallbackScale2SFX;

  PROCEDURE Scale2SFX*;
  BEGIN
  DoScale(2, CallbackScale2SFX);
  END Scale2SFX;


  PROCEDURE CallbackScale3SFX(in: SET; VAR out: SET);
  VAR a,b,c,d,e,f,g,h,i,j,k,l,m: INTEGER;
    p0, p1, d0, d1, a0, a2, a6, a8: BOOLEAN;
  BEGIN
    a := ORD(0 IN in); b := ORD(1 IN in); c := ORD(2 IN in);
    d := ORD(3 IN in); e := ORD(4 IN in); f := ORD(5 IN in);
    g := ORD(6 IN in); h := ORD(7 IN in); i := ORD(8 IN in);
    j := ORD(9 IN in); k := ORD(10 IN in);
    l := ORD(11 IN in); m := ORD(12 IN in);
    p0 := (b # f) & (d # h);
    p1 := (b # d) & (f # h);
    d0 := (a = e) OR (e = i);
    d1 := (c = e) OR (e = g);
    a0 := (b = d) & p0 & ((a # e) OR d1 OR (a = j) OR (a = k));
    a2 := (b = f) & p1 & ((c # e) OR d0 OR (c = j) OR (c = l));
    a6 := (d = h) & p1 & ((e # g) OR d0 OR (g = k) OR (g = m));
    a8 := (f = h) & p0 & ((e # i) OR d1 OR (i = l) OR (i = m));
    IF e # 0 THEN out := {0 .. 8} ELSE out := {} END;
    IF a0 OR ((b = d) & (((c = e) & (c # j) & (a # e)) OR ((e = g) & (a # e) & (g # k)))) THEN CopySetBit(in, 3, out, 0) END;
    IF a2 OR ((b = f) & (((a = e) & (a # j) & (c # e)) OR ((e = i) & (c # e) & (i # l)))) THEN CopySetBit(in, 5, out, 2) END;
    IF a6 OR ((d = h) & (((a = e) & (a # k) & (e # g)) OR ((e = i) & (e # g) & (i # m)))) THEN CopySetBit(in, 3, out, 6) END;
    IF a8 OR ((f = h) & (((c = e) & (c # l) & (e # i)) OR ((e = g) & (e # i) & (g # m)))) THEN CopySetBit(in, 5, out, 8) END;
    IF (a0 & (c # e)) OR (a2 & (a # e)) THEN CopySetBit(in, 1, out, 1) END;
    IF (a0 & (e # g)) OR (a6 & (a # e)) THEN CopySetBit(in, 3, out, 3) END;
    IF (a8 & (c # e)) OR (a2 & (e # i)) THEN CopySetBit(in, 5, out, 5) END;
    IF (a8 & (e # g)) OR (a6 & (e # i)) THEN CopySetBit(in, 7, out, 7) END;
  END CallbackScale3SFX;

  PROCEDURE Scale3SFX*;
  BEGIN
  DoScale(3, CallbackScale3SFX);
  END Scale3SFX;

END GrowFont.
