MODULE ConvertPCFFont;
  (* Based on https://github.com/io-core/Edit/blob/795889b215dd831f44369f0a6edc0f8ec6caf05c/Fonts.Mod *)
  (* See also https://fontforge.org/docs/techref/pcf-format.html *)

  IMPORT Files, Texts, Oberon;

  CONST PcfFileId = 70636601H;

  PROCEDURE ReadInt16(VAR R: Files.Rider; bigEndian: BOOLEAN; VAR v: INTEGER);
    VAR b0, b1: BYTE;
  BEGIN Files.ReadByte(R, b0); Files.ReadByte(R, b1);
    IF bigEndian THEN v := b0 * 100H + b1 ELSE v := b0 + b1 * 100H END
  END ReadInt16;

  PROCEDURE ReadInt32(VAR R: Files.Rider; bigEndian: BOOLEAN; VAR v: INTEGER);
    VAR b0, b1, b2, b3: BYTE;
  BEGIN
    Files.ReadByte(R, b0); Files.ReadByte(R, b1);
    Files.ReadByte(R, b2); Files.ReadByte(R, b3);
    IF bigEndian THEN
      v := b0 * 1000000H + b1 * 10000H + b2 * 100H + b3
    ELSE
      v := 1000000H * b3 + 10000H * b2 + 100H * b1 + b0
    END
  END ReadInt32;

  PROCEDURE WriteInt16(VAR R: Files.Rider; v: INTEGER);
  BEGIN Files.WriteByte(R, v MOD 100H); Files.WriteByte(R, v DIV 100H);
  END WriteInt16;

  PROCEDURE Reverse(b:BYTE): BYTE;
    VAR r, mask: BYTE;
  BEGIN
    r := 0; mask := 80H;
    WHILE b # 0 DO IF ODD(b) THEN INC(r, mask) END; b := b DIV 2; mask := mask DIV 2 END
  RETURN r
  END Reverse;

  PROCEDURE MaybeReverse(b: BYTE; doIt: BOOLEAN): BYTE;
    VAR r: BYTE;
  BEGIN
    IF doIt THEN r := Reverse(b) ELSE r := b END
  RETURN r
  END MaybeReverse;

  PROCEDURE ConvertUpTo(maxCodepoint: INTEGER);
    VAR i, j, k, minY, maxX, maxY, typ, bofs, gcount, mw, mh, first, last, offset, firstHigh, lastHigh: INTEGER;
      METRICSoffset, BDFACCELERATORSoffset, BDFENCODINGSoffset, BITMAPSoffset: INTEGER;
      S: Texts.Scanner; FR, FW: Files.File; RR, RW: Files.Rider; b, bitflags: BYTE; bigEndian, bigEndianBits: BOOLEAN;
  BEGIN
    Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    IF S.class = Texts.Name THEN
      FR := Files.Old(S.s); Files.Set(RR, FR, 0); ReadInt32(RR, FALSE, i); Texts.Scan(S);
    END;
    IF (S.class = Texts.Name) & (i = PcfFileId) THEN
      FW := Files.New(S.s); Files.Set(RW, FW, 0); Texts.Scan(S);
      Files.WriteByte(RW, 0DBH); (* id *)
      Files.WriteByte(RW, 0); (* abstraction *)
      Files.WriteByte(RW, 0); (* family *)
      Files.WriteByte(RW, 0); (* variant *)
      ReadInt32(RR, FALSE, i);
      IF i > 9 THEN i := 9 END;
      METRICSoffset := -1; BDFACCELERATORSoffset := -1; BDFENCODINGSoffset := -1; BITMAPSoffset := -1;
      WHILE i > 0 DO
        ReadInt32(RR, FALSE, typ); ReadInt32(RR, FALSE, j);
        ReadInt32(RR, FALSE, j); ReadInt32(RR, FALSE, offset);
        IF typ = 4 THEN METRICSoffset := offset END;
        IF typ = 8 THEN BITMAPSoffset := offset END;
        IF typ = 32 THEN BDFENCODINGSoffset := offset END;
        IF typ = 256 THEN BDFACCELERATORSoffset := offset END;
        DEC(i)
      END;
      ASSERT((METRICSoffset # -1) & (BDFACCELERATORSoffset # -1) & (BDFENCODINGSoffset # -1) & (BITMAPSoffset # -1));
      Files.Set(RR, FR, BDFACCELERATORSoffset);
      ReadInt32(RR, FALSE, typ);
      bitflags := typ MOD 10H;
      bitflags := bitflags DIV 4 * 4 + bitflags MOD 4 MOD 3;
      bigEndian := (bitflags DIV 4 MOD 2 = 1);
      bigEndianBits := (bitflags DIV 8 MOD 2 = 1);
      ASSERT((typ = bitflags) OR (typ = 100H + bitflags));
      Files.Set(RR, FR, BDFACCELERATORSoffset + 12 + ORD(bigEndian) * 2);
      ReadInt16(RR, bigEndian, maxY);
      Files.Set(RR, FR, BDFACCELERATORSoffset + 16 + ORD(bigEndian) * 2);
      ReadInt16(RR, bigEndian, minY); minY := -minY;
      Files.Set(RR, FR, BDFACCELERATORSoffset + 44);
      ReadInt16(RR, bigEndian, maxX); (*maxwidth*)
      WriteInt16(RW, maxY - minY); (* height *)
      WriteInt16(RW, 0); (* minX *)
      WriteInt16(RW, maxX); (* maxX *)
      WriteInt16(RW, minY); (* minY *)
      WriteInt16(RW, maxY); (* maxY *)
      Files.Set(RR, FR, BDFENCODINGSoffset);
      ReadInt32(RR, FALSE, typ);
      ASSERT(typ = bitflags);
      Files.Set(RR, FR, BDFENCODINGSoffset + 4);
      ReadInt16(RR, bigEndian, first);
      ReadInt16(RR, bigEndian, last);
      ReadInt16(RR, bigEndian, firstHigh);
      ReadInt16(RR, bigEndian, lastHigh);
      i := (last - first + 1) * (lastHigh - firstHigh + 1);
      firstHigh := firstHigh * 10000H + first;
      maxCodepoint := maxCodepoint - firstHigh;
      IF maxCodepoint >= i THEN maxCodepoint := i - 1 END;
      (* count runs *)
      Files.Set(RR, FR, BDFENCODINGSoffset + 14);
      maxX := 0; maxY := 0; last := -2;
      FOR i := 0 TO maxCodepoint DO
        ReadInt16(RR, bigEndian, offset);
        IF offset # 65535 THEN
          IF last # i - 1 THEN INC(maxY) END;
          last := i
        END;
      END;
      WriteInt16(RW, maxY);
      (* write runs *)
      Files.Set(RR, FR, BDFENCODINGSoffset + 14);
      first := -2; last := -2;
      FOR i := 0 TO maxCodepoint DO
        ReadInt16(RR, bigEndian, offset);
        IF offset # 65535 THEN
          IF last # i - 1 THEN
            IF last # -2 THEN
              WriteInt16(RW, first+firstHigh);
              WriteInt16(RW, last+firstHigh+1);
              INC(maxX, last-first+1);
              DEC(maxY)
            END;
            first := i;
          END;
          last := i
        END
      END;
      IF last # -2 THEN
        WriteInt16(RW, first + firstHigh);
        WriteInt16(RW, last + firstHigh + 1);
        INC(maxX, last - first + 1);
        DEC(maxY)
      END;
      ASSERT(maxY = 0);
      Files.Set(RR, FR, METRICSoffset);
      ReadInt32(RR, FALSE, typ);
      ASSERT(typ = 100H + bitflags); (* PCF_COMPRESSED_METRICS *)
      (* write boxes *)
      FOR i := 0 TO maxCodepoint DO
        Files.Set(RR, FR, BDFENCODINGSoffset + 14 + (i*2));
        ReadInt16(RR, bigEndian, offset);
        IF offset # 65535 THEN
          INC(maxY);
          Files.Set(RR, FR, METRICSoffset + 8 + offset * 5);
          Files.ReadByte(RR, b); mw := b - 128;
          IF mw < 0 THEN mw := 0 END;
          Files.ReadByte(RR, b); mh := b - 128;
          Files.ReadByte(RR, b); mh := mh + b - 128;
          WriteInt16(RW, mw); WriteInt16(RW, 0); WriteInt16(RW, 128 - b);
          WriteInt16(RW, mw); WriteInt16(RW, mh)
        END
      END;
      ASSERT(maxY = maxX);
      Files.Set(RR, FR, BITMAPSoffset);
      ReadInt32(RR, FALSE, typ);
      ASSERT(typ = bitflags);
      ReadInt32(RR, bigEndian, gcount);
      ASSERT(gcount >= maxX);
      (* write glyphs *)
      FOR i := 0 TO maxCodepoint DO
        Files.Set(RR, FR, BDFENCODINGSoffset + 14 + (i*2));
        ReadInt16(RR, bigEndian, offset);
        IF offset # 65535 THEN
          DEC(maxY);
          Files.Set(RR, FR, METRICSoffset + 8 + offset * 5);
          Files.ReadByte(RR, b); mw := b - 128;
          IF mw < 0 THEN mw := 0 END;
          maxX := (mw + 7) DIV 8;
          IF bitflags MOD 4 = 1 THEN maxX := (maxX + 1) DIV 2 * 2
          ELSIF bitflags MOD 4 = 2 THEN maxX := (maxX + 3) DIV 4 * 4 END;
          Files.ReadByte(RR, b); mh := b - 128;
          Files.ReadByte(RR, b); mh := mh + b - 128;
          Files.Set(RR, FR, BITMAPSoffset + 8 + offset * 4);
          ReadInt32(RR, bigEndian, bofs);
          bofs := BITMAPSoffset + 8 + 4 * gcount + 16 + bofs;
          j := mh - 1;
          FOR j := mh - 1 TO 0 BY -1 DO
            Files.Set(RR, FR, bofs + j * maxX);
            FOR k := 1 TO (mw + 7) DIV 8 DO
              Files.ReadByte(RR, b); Files.WriteByte(RW, MaybeReverse(b, bigEndianBits))
            END
          END;
          DEC(j)
        END;
      END;
      ASSERT(maxY = 0);
      Files.Register(FW);
    END;
    Files.Close(FR)
  END ConvertUpTo;

  PROCEDURE Convert*;
  BEGIN ConvertUpTo(0FFFFH)
  END Convert;

  PROCEDURE ConvertASCIIOnly*;
  BEGIN ConvertUpTo(7FH)
  END ConvertASCIIOnly;

END ConvertPCFFont.