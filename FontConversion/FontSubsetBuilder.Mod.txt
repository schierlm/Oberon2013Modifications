MODULE FontSubsetBuilder;
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

  PROCEDURE Extract*;
    VAR i, j, w, h, beg, end, p, mark, listlen, keepfrom, keepto, NofRunsR, NofRunsW: INTEGER;
      b: BYTE;
      FR, FW: Files.File;
      RR, RW: Files.Rider;
      S: Texts.Scanner;
      skiplist, keeplist: ARRAY 256 OF INTEGER;
  BEGIN
    Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    IF S.class = Texts.Name THEN
      FR := Files.Old(S.s); Files.Set(RR, FR, 0); Files.ReadByte(RR, b); Texts.Scan(S);
    END;
    IF (S.class = Texts.Name) & (b = FontFileId) THEN
      FW := Files.New(S.s); Files.Set(RW, FW, 0); Texts.Scan(S);
      Files.WriteByte(RW, b);
      CopyBytes(RR, RW, 13); (*abstraction, family, variant; height, minX, maxX, minY, maxY *)
      ReadInt16(RR, NofRunsR); NofRunsW := 0; p := Files.Pos(RW); WriteInt16(RW, NofRunsW);
      listlen := 0; skiplist[0] := 0; keeplist[0] := 0; keepto := -2;
      FOR i := 0 TO NofRunsR - 1 DO
        ReadInt16(RR, beg); ReadInt16(RR, end);
        WHILE beg < end DO
          WHILE beg > keepto DO
            IF S.class = Texts.Int THEN
              keepfrom := S.i; Texts.Scan(S); ASSERT(keepfrom > keepto + 1);
              IF (S.class = Texts.Char) & ((S.c = "-") OR (S.c = "*")) THEN
                Texts.Scan(S); IF S.class = Texts.Int THEN keepto := S.i; Texts.Scan(S) ELSE keepto := 10000H END
              ELSIF (S.class = Texts.Int) & (S.i < 0) THEN
                keepto := -S.i; Texts.Scan(S)
              ELSE
                keepto := keepfrom
              END; ASSERT(keepto >= keepfrom)
            ELSE
              keepfrom := 10000H; keepto := 10000H
            END
          END;
          IF beg < keepfrom THEN
            IF keepfrom > end THEN mark := end ELSE mark := keepfrom END;
            IF keeplist[listlen] # 0 THEN INC(listlen); keeplist[listlen] := 0; skiplist[listlen] := 0 END;
            INC(skiplist[listlen], mark - beg); beg := mark;
          END;
          IF beg < end THEN
            ASSERT(beg >= keepfrom);
            IF keepto + 1 > end THEN mark := end ELSE mark := keepto + 1 END;
            WriteInt16(RW, beg); WriteInt16(RW, mark); INC(NofRunsW);
            INC(keeplist[listlen], mark - beg); beg := mark;
          END
        END
      END;
      mark := Files.Pos(RW); Files.Set(RW, FW, p); WriteInt16(RW, NofRunsW); Files.Set(RW, FW, mark);
      FOR i := 0 TO listlen DO
        mark := 0;
        FOR j := 0 TO skiplist[i]-1 DO
          ReadInt16(RR, p); (*dx*)
          ReadInt16(RR, p); (*x*)
          ReadInt16(RR, p); (*y*)
          ReadInt16(RR, w);
          ReadInt16(RR, h);
          INC(mark, ((w + 7) DIV 8) * h);
        END;
        skiplist[i] := mark;
        mark := 0;
        FOR j := 0 TO keeplist[i]-1 DO
          ReadInt16(RR, p); WriteInt16(RW, p); (*dx*)
          ReadInt16(RR, p); WriteInt16(RW, p); (*x*)
          ReadInt16(RR, p); WriteInt16(RW, p); (*y*)
          ReadInt16(RR, w); WriteInt16(RW, w);
          ReadInt16(RR, h); WriteInt16(RW, h);
          INC(mark, ((w + 7) DIV 8) * h);
        END;
        keeplist[i] := mark;
      END;
      FOR i := 0 TO listlen DO
        FOR j := 0 TO skiplist[i] - 1 DO Files.ReadByte(RR, b) END;
        CopyBytes(RR, RW, keeplist[i]);
      END;
      Files.Register(FW)
    END;
    Files.Close(FR)
  END Extract;
END FontSubsetBuilder.
