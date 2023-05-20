MODULE BiSixelFontBuilder;

  IMPORT Files;

  PROCEDURE WriteInt16(VAR R: Files.Rider; v: INTEGER);
  BEGIN Files.WriteByte(R, v MOD 100H); Files.WriteByte(R, v DIV 100H);
  END WriteInt16;

  PROCEDURE Create*();
    VAR group, i, v, baseY, boxY, boxDX, boxH: INTEGER;
      F: Files.File; R: Files.Rider;
  BEGIN
    F := Files.New("BiSixel.Scn.Fnt"); Files.Set(R, F, 0);
    Files.WriteByte(R, 0DBH); (* id *)
    Files.WriteByte(R, 0); (* abstraction *)
    Files.WriteByte(R, 0); (* family *)
    Files.WriteByte(R, 0); (* variant *)
    WriteInt16(R, 12); (* height *)
    WriteInt16(R, 0); (* minX *)
    WriteInt16(R, 1); (* maxX *)
    WriteInt16(R, -3); (* minY *)
    WriteInt16(R, 9); (* maxY *)
    WriteInt16(R, 5); (* NofRuns *)
    (* write runs *)
    WriteInt16(R, 9); WriteInt16(R, 9 + 1); (* TAB *)
    WriteInt16(R, ORD(" ")); WriteInt16(R, ORD(" ") + 1); (* SPACE *)
    WriteInt16(R, ORD("0")); WriteInt16(R, ORD("9") + 1); (* 0-9 *)
    WriteInt16(R, ORD("A")); WriteInt16(R, ORD("Z") + 1); (* A-Z *)
    WriteInt16(R, ORD("a")); WriteInt16(R, ORD("z") + 1); (* a-z *)
    (* write boxes *)
    WriteInt16(R, 12); WriteInt16(R, 0); WriteInt16(R, 0);
    WriteInt16(R, 0); WriteInt16(R, 0); (* TAB *)
    WriteInt16(R, 1); WriteInt16(R, 0); WriteInt16(R, 0);
    WriteInt16(R, 0); WriteInt16(R, 0); (* SPACE *)
    boxDX := 0;
    FOR group := 0 TO 3 DO (* groups *)
      IF group = 3 THEN boxDX := 1; baseY := 1 ELSE baseY := group * 4 - 3 END;
      FOR i := 1 TO 15 DO
        v := i; boxH := 1; boxY := baseY;
        WHILE ~ODD(v) DO INC(boxY); v := v DIV 2 END;
        WHILE v > 1 DO INC(boxH); v := v DIV 2 END;
        WriteInt16(R, boxDX); WriteInt16(R, 0 (* boxX *)); WriteInt16(R, boxY);
        WriteInt16(R, 1 (* boxW *)); WriteInt16(R, boxH)
      END;
    END;
    WriteInt16(R, 1); WriteInt16(R, 0); WriteInt16(R, -3);
    WriteInt16(R, 1); WriteInt16(R, 12); (* y *)
    WriteInt16(R, 12); WriteInt16(R, 0); WriteInt16(R, -3);
    WriteInt16(R, 12); WriteInt16(R, 12); (* z *)
    (* write glyphs *)
    FOR group := 0 TO 3 DO (* groups *)
      FOR i := 1 TO 15 DO
        v := i;
        WHILE ~ODD(v) DO v := v DIV 2 END;
        WHILE v > 1 DO Files.WriteByte(R, v MOD 2); v := v DIV 2 END;
        Files.WriteByte(R, 1)
      END
    END;
    FOR i := 1 TO 12 DO Files.WriteByte(R, 1) END; (* y *)
    FOR i := 1 TO 12 DO Files.WriteByte(R, 0FFH);Files.WriteByte(R, 0FH) END; (* z *)
    Files.Register(F);
  END Create;

END BiSixelFontBuilder.