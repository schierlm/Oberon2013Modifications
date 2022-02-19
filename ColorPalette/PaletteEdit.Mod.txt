MODULE PaletteEdit;
  IMPORT Display, Texts, Oberon;

  VAR
    S: Texts.Scanner;
    W: Texts.Writer;
    val: INTEGER;

  PROCEDURE Log*();
    VAR
      col, max: INTEGER;
  BEGIN
    max := LSL(1, Display.Depth) - 1;
    Texts.OpenWriter(W);
    FOR col := 0 TO max DO
      IF Display.GetPalette(col, val) THEN
        Texts.WriteString(W, "PaletteEdit.Set ");
        Texts.WriteInt(W, col, 2);
        Texts.WriteString(W, " ");
        Texts.WriteHex(W, val);
        Texts.WriteString(W, "H");
        Texts.WriteLn(W)
      END
    END;
    Texts.Append(Oberon.Log, W.buf)
  END Log;

  PROCEDURE Set*();
    VAR
      col, val: INTEGER;
  BEGIN
    Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos);
    Texts.Scan(S);
    IF S.class = Texts.Int THEN col := S.i ELSE col := 0 END;
    Texts.Scan(S);
    IF S.class = Texts.Int THEN val := S.i ELSE val := 0 END;
    IF (col >= 0) & (col < LSL(1, Display.Depth)) THEN Display.SetPalette(col, val) END
  END Set;

  PROCEDURE SetAll*();
    VAR
      max, col, val: INTEGER;
  BEGIN
    max := LSL(1, Display.Depth) - 1;
    Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos);
    FOR col := 0 TO max DO
      Texts.Scan(S);
      IF S.class = Texts.Int THEN val := S.i ELSE val := 0 END;
      Display.SetPalette(col, val)
    END
  END SetAll;

END PaletteEdit.
