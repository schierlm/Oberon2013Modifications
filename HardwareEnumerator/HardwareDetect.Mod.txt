MODULE HardwareDetect;
  IMPORT SYSTEM, Kernel, Display, Texts, Oberon;

  VAR
    log: Texts.Writer;

  PROCEDURE WriteHwID(val: INTEGER);
    VAR i, tmp: INTEGER; str: ARRAY 5 OF CHAR; valid: BOOLEAN;
  BEGIN
    Texts.WriteHex(log, val);
    valid := TRUE; str[4] := 0X; tmp := val;
    FOR i := 3 TO 0 BY -1 DO
      str[i] := CHR(tmp MOD 100H); tmp := tmp DIV 100H;
      IF ~(((ORD(str[i]) >= ORD("A")) & (ORD(str[i]) <= ORD("Z")))
          OR ((ORD(str[i]) >= ORD("a")) & (ORD(str[i]) <= ORD("z")))
          OR ((ORD(str[i]) >= ORD("0")) & (ORD(str[i]) <= ORD("9")))) THEN
        valid := FALSE;
      END
    END;
    IF valid THEN
      Texts.WriteString(log, " '");
      Texts.WriteString(log, str);
      Texts.WriteString(log, "'");
    ELSE
      Texts.WriteString(log, " (");
      Texts.WriteInt(log, val, 1);
      Texts.WriteString(log, ")");
    END
  END WriteHwID;

  PROCEDURE EnumerateHardware*;
    VAR version, buflen, buflen2, i, j: INTEGER; buffer, buffer2: ARRAY 256 OF INTEGER;
  BEGIN buflen := 0;
    SYSTEM.PUT(-4, 0);
    SYSTEM.GET(-4, version);
    Texts.WriteString(log, "Hardware Enumerator Version ");
    Texts.WriteInt(log, version, 1);
    Texts.WriteLn(log);
    IF version = 1 THEN
      REPEAT SYSTEM.GET(-4, buffer[buflen]); INC(buflen) UNTIL buffer[buflen - 1] = 0; DEC(buflen);
      FOR i := 0 TO buflen - 1 DO
        Texts.WriteLn(log);
        Texts.WriteString(log, "Hardware ");
        WriteHwID(buffer[i]);
        Texts.Write(log, ":");
        Texts.WriteLn(log);
        SYSTEM.PUT(-4, buffer[i]);
        FOR j := 0 TO LEN(buffer2) - 1 DO
          SYSTEM.GET(-4, buffer2[j]);
          IF buffer2[j] # 0 THEN buflen2 := j + 1 END
        END;
        FOR j := 0 TO buflen2 - 1 DO
          Texts.WriteString(log, "    ");
          WriteHwID(buffer2[j]);
          Texts.WriteLn(log);
        END
      END
    END;
    Texts.Append(Oberon.Log, log.buf);
  END EnumerateHardware;

  PROCEDURE MaxAddress(): INTEGER;
    VAR i, j, maxAdr: INTEGER;
      ok: BOOLEAN;
  BEGIN
    maxAdr := 0100000H DIV 2;
    ok := FALSE;
    WHILE ~ok DO
      ok := TRUE;
      maxAdr := maxAdr * 2;
      i := 1;
      WHILE ok & (i < 5) DO
        SYSTEM.GET(SYSTEM.ADR(i) + maxAdr, j);
        IF i # j THEN ok := FALSE END;
        INC(i)
      END;
      j := 1;
      WHILE ok & (j < 5) DO
        SYSTEM.GET(SYSTEM.ADR(j) + maxAdr, i);
        IF j # i THEN ok := FALSE END;
        INC(j)
      END;
    END;
    DEC(maxAdr);
  RETURN maxAdr
  END MaxAddress;

  PROCEDURE DetectCPU*();
  BEGIN
    Texts.WriteString(log, "CPUID ");
    Texts.WriteHex(log, SYSTEM.H(1));
    Texts.WriteLn(log);
    Texts.WriteString(log, "AddrSpace ");
    Texts.WriteHex(log, 0);
    Texts.WriteString(log, "-");
    Texts.WriteHex(log, MaxAddress());
    Texts.WriteLn(log);
    Texts.WriteString(log, "Code/Stack ");
    Texts.WriteHex(log, SYSTEM.REG(12));
    Texts.WriteString(log, "-");
    Texts.WriteHex(log, Kernel.stackOrg - 1);
    Texts.WriteLn(log);
    Texts.WriteString(log, "Heap ");
    Texts.WriteHex(log, Kernel.heapOrg);
    Texts.WriteString(log, "-");
    Texts.WriteHex(log, Kernel.heapLim);
    Texts.WriteLn(log);
    Texts.Append(Oberon.Log, log.buf);
  END DetectCPU;

  PROCEDURE DetectDisplay*();
  BEGIN
    Texts.WriteString(log, "Display ");
    Texts.WriteHex(log, Display.Base);
    Texts.WriteString(log, "-");
    Texts.WriteHex(log, Display.Base + Display.Span * Display.Height - 1);
    Texts.WriteLn(log);
    Texts.WriteLn(log);
    Texts.WriteString(log, "Display Resolution ");
    Texts.WriteInt(log, Display.Width, 1);
    Texts.WriteString(log, "x");
    Texts.WriteInt(log, Display.Height, 1);
    Texts.WriteString(log, "x");
    Texts.WriteInt(log, Display.Depth, 1);
    Texts.WriteString(log, " (Stride ");
    Texts.WriteInt(log, Display.Span, 1);
    Texts.WriteString(log, ")");
    Texts.WriteLn(log);
    Texts.Append(Oberon.Log, log.buf);
  END DetectDisplay;

  PROCEDURE Detect*();
  BEGIN DetectCPU(); DetectDisplay(); EnumerateHardware()
  END Detect;

BEGIN
  Texts.OpenWriter(log);
END HardwareDetect.
