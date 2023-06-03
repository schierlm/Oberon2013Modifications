MODULE UnicodeFontIndex;
  IMPORT Files, Texts, Oberon;

  CONST IdxFileId = 01694675H;

  TYPE FileName = ARRAY 32 OF CHAR;

    IndexPage = POINTER TO IndexPageDesc;
    IndexPageDesc = RECORD
      skipRuns, skipBoxes, glyphOffs: ARRAY 64 OF INTEGER
    END;

  PROCEDURE ReadInt16(VAR R: Files.Rider; VAR v: INTEGER);
    VAR b0, b1: BYTE;
  BEGIN Files.ReadByte(R, b0); Files.ReadByte(R, b1); v := b1 * 100H + b0;
  END ReadInt16;

  PROCEDURE WriteInt16(VAR R: Files.Rider; v: INTEGER);
  BEGIN ASSERT((v = -1) OR (v DIV 10000H = 0)); Files.WriteByte(R, v MOD 100H); Files.WriteByte(R, v DIV 100H);
  END WriteInt16;

  PROCEDURE InitPage(VAR p: IndexPage);
    VAR i: INTEGER;
  BEGIN
    IF p = NIL THEN
      NEW(p);
      FOR i := 0 TO 63 DO p.skipRuns[i] := -1; p.skipBoxes[i] := -1; p.glyphOffs[i] := -1 END
    END
  END InitPage;

  PROCEDURE BuildIndex(fntname, idxname: FileName);
    VAR F: Files.File; R: Files.Rider;
      pages: ARRAY 16 OF IndexPage;
      i, j, w, h, run, totalRuns, totalBoxes, beg, end, range, lastRange, glyphOffset: INTEGER;
  BEGIN
      FOR i := 0 TO 15 DO pages[i] := NIL END;
      F := Files.Old(fntname); run := 0; lastRange := -1; totalBoxes := 0;
      Files.Set(R, F, 14); ReadInt16(R, totalRuns);
      WHILE run # totalRuns DO
        ReadInt16(R, beg); ReadInt16(R, end); i := beg;
        WHILE i < end DO
          ASSERT((i = beg) OR (i MOD 40H = 0));
          range := i DIV 40H;
          IF range # lastRange THEN
            lastRange := range;
            InitPage(pages[range DIV 40H]);
            pages[range DIV 40H].skipRuns[range MOD 40H] := run;
            pages[range DIV 40H].skipBoxes[range MOD 40H] := totalBoxes
          END;
          j := 40H - i MOD 40H;
          IF i + j > end THEN j := end - i END;
          INC(i, j); INC(totalBoxes, j)
        END; ASSERT(i = end);
        INC(run)
      END;
      glyphOffset := 14 + 2 + 4 * totalRuns + 10 * totalBoxes;
      i := 0; range := 0;
      WHILE i # totalBoxes DO
        WHILE (range < 400H) & (pages[range DIV 40H] = NIL) DO
          range := (range DIV 40H + 1) * 40H
        ELSIF (range < 400H) & (pages[range DIV 40H].skipBoxes[range MOD 40H] = -1) DO
          INC(range)
        END;
        IF range < 400H THEN
          ASSERT((pages[range DIV 40H].skipBoxes[range MOD 40H] # -1)
            & (pages[range DIV 40H].glyphOffs[range MOD 40H] = -1));
          IF pages[range DIV 40H].skipBoxes[range MOD 40H] = i THEN
            pages[range DIV 40H].glyphOffs[range MOD 40H] := glyphOffset;
            INC(range)
          END
        END;
        ReadInt16(R, j); ReadInt16(R, j); ReadInt16(R, j);
        ReadInt16(R, w); ReadInt16(R, h);
        glyphOffset := glyphOffset + (w + 7) DIV 8 * h;
        INC(i)
      END;
      ASSERT(glyphOffset = Files.Length(F));
      F := Files.New(idxname);
      Files.Set(R, F, 0);
      Files.WriteInt(R, IdxFileId);
      j := 0;
      FOR i := 0 TO 15 DO
        IF pages[i] # NIL THEN INC(j); Files.WriteByte(R, j) ELSE Files.WriteByte(R, 0) END
      END;
      FOR i := 0 TO 15 DO
        IF pages[i] # NIL THEN
          FOR j := 0 TO 63 DO
            WriteInt16(R, pages[i].skipRuns[j]);
            WriteInt16(R, pages[i].skipBoxes[j]);
            Files.WriteInt(R, pages[i].glyphOffs[j])
          END
        END
      END;
      Files.Register(F);
  END BuildIndex;

  PROCEDURE Build*;
    VAR S: Texts.Scanner; T: Texts.Text;
      beg, end, time: INTEGER;
      idxname: FileName;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    IF (S.class = Texts.Char) & (S.c = "^") THEN
      Oberon.GetSelection(T, beg, end, time);
      IF time >= 0 THEN Texts.OpenScanner(S, T, beg); Texts.Scan(S) END
    END;
    WHILE S.class = Texts.Name DO
      beg := 0; WHILE S.s[beg] # 0X DO idxname[beg] := S.s[beg]; INC(beg) END;
      IF (beg > 4) & (S.s[beg-4] = ".") & (S.s[beg-3] = "F") & (S.s[beg-2] = "n") & (S.s[beg-1] = "t") THEN
        idxname[beg-3] := "u"; idxname[beg-2] := "F"; idxname[beg-1] := "i"; idxname[beg] := 0X;
        BuildIndex(S.s, idxname); Texts.Scan(S)
      ELSE
        S.class := Texts.Inval;
      END;
    END
  END Build;

END UnicodeFontIndex.