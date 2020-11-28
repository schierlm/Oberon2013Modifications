MODULE MemorySplit;
  IMPORT SYSTEM, Kernel, Texts, Oberon;

  VAR
    log: Texts.Writer;

  PROCEDURE Show*;
    VAR a: INTEGER;
  BEGIN
    Texts.WriteString(log, "Configured Split: ");
    SYSTEM.GET(4, a);
    Texts.WriteHex(log, a);
    Texts.WriteLn(log);
    Texts.WriteString(log, "Actual Split: ");
    Texts.WriteHex(log, Kernel.heapOrg);
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
  END Show;

  PROCEDURE Set*;
  VAR
    s: Texts.Scanner;
    sec: Kernel.Sector;
    t: Texts.Text;
    val, beg, end, time: INTEGER;
  BEGIN
    Texts.OpenScanner(s, Oberon.Par.text, Oberon.Par.pos);
    Texts.Scan(s);
    IF (s.class = Texts.Char) & (s.c = "^") THEN
      Oberon.GetSelection(t, beg, end, time);
      IF time >= 0 THEN
        Texts.OpenScanner(s, t, beg); Texts.Scan(s)
      END
    END;
    IF s.class = Texts.Int THEN
      val := s.i;
      Kernel.GetSector(2*29, sec);
      SYSTEM.PUT(SYSTEM.ADR(sec)+4, val);
      Kernel.PutSector(2*29, sec)
    END
  END Set;

BEGIN Texts.OpenWriter(log);
END MemorySplit.
