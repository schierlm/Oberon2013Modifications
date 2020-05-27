MODULE ORInspect;
  IMPORT SYSTEM, Files, Modules, Texts, Oberon;

  CONST
    Byte = 1; Bool = 2; Char = 3; Int = 4; Real = 5; Set = 6;
    Pointer = 7; Proc = 10; CharArray = 11; ByteArray = 12;
    Record = 13; VarParam = 20; OpenArrayParam = 21;

  TYPE GetDataCallback* = PROCEDURE (adr, len: INTEGER; VAR val: INTEGER);
    KeepAlivePointer = POINTER TO DummyDesc;
    DummyDesc = RECORD END;

  VAR W: Texts.Writer;
    keepalive: ARRAY 256 OF KeepAlivePointer;
    keepaliveNext, keepaliveMax: INTEGER;

  PROCEDURE GetData*(adr, len: INTEGER; VAR val: INTEGER);
  VAR b: BYTE;
  BEGIN
    IF len = 1 THEN
      SYSTEM.GET(adr, b); val := b
    ELSIF len = 4 THEN
      SYSTEM.GET(adr, val)
    ELSIF len = 0 THEN
      IF keepaliveMax > 0 THEN
        keepalive[keepaliveNext] := SYSTEM.VAL(KeepAlivePointer, adr);
        keepaliveNext := (keepaliveNext + 1) MOD keepaliveMax
      END
    ELSE
      ASSERT(FALSE)
    END
  END GetData;

  PROCEDURE OpenInspectSymbolFile(M: Modules.Module) : Files.File;
  VAR i: INTEGER;
    name: ARRAY 32 OF CHAR;
  BEGIN i := 0;
    WHILE M.name[i] # 0X DO name[i] := M.name[i]; INC(i) END;
    name[i] := "."; name[i+1] := "i"; name[i+2] := "s"; name[i+3] := "y"; name[i+4] := 0X
  RETURN Files.Old(name)
  END OpenInspectSymbolFile;

  PROCEDURE WriteHex*(VAR W: Texts.Writer; x, len: INTEGER);
    VAR i: INTEGER; y: LONGINT;
      a: ARRAY 10 OF CHAR;
  BEGIN i := 0;
    REPEAT y := x MOD 10H;
      IF y < 10 THEN a[i] := CHR(y + 30H) ELSE a[i] := CHR(y + 37H) END;
      x := x DIV 10H; INC(i)
    UNTIL i = len;
    REPEAT DEC(i); Texts.Write(W, a[i]) UNTIL i = 0
  END WriteHex;

  PROCEDURE WriteByteArray(VAR offs, len: INTEGER; Get: GetDataCallback);
    VAR b, b2: INTEGER; cnt: INTEGER;
  BEGIN
    WHILE len > 0 DO
      Get(offs, 1, b); cnt := 0;
      REPEAT INC(cnt); INC(offs); DEC(len); Get(offs, 1, b2) UNTIL (len = 0) OR (b # b2);
      Texts.WriteString(W, " ");
      WriteHex(W, b, 2);
      IF cnt > 1 THEN Texts.WriteString(W, "*"); Texts.WriteInt(W, cnt, 1) END
    END;
    WHILE offs MOD 4 # 0 DO INC(offs) END
  END WriteByteArray;

  PROCEDURE InspectSkip(VAR R: Files.Rider; length: INTEGER);
  VAR t: INTEGER; buffer: ARRAY 100 OF CHAR;
  BEGIN
    WHILE length > 0 DO
      Files.ReadString(R, buffer);
      ASSERT(buffer[0] # 0X);
      Files.ReadInt(R, t);
      IF (t = Byte) OR (t = Bool) OR (t = Char) THEN
        DEC(length)
      ELSIF (t = Int) OR (t = Set) OR (t = Real) OR (t = Pointer) OR (t = Record) OR (t = VarParam) OR (t = Proc) THEN
        DEC(length, 4)
      ELSIF (t = OpenArrayParam) THEN
        DEC(length, 8)
      ELSIF (t = CharArray) OR (t = ByteArray) THEN
        Files.ReadInt(R, t);
        DEC(length, t)
      END;
    END;
  END InspectSkip;

  PROCEDURE InspectLoop*(VAR R: Files.Rider; VAR offs: INTEGER; index: INTEGER; linePrefix: ARRAY OF CHAR; Get: GetDataCallback; commandPrefix: ARRAY OF CHAR);
  VAR i, j, k, t, oldpos: INTEGER; r: REAL;
    buffer: ARRAY 100 OF CHAR;
  BEGIN
    Files.ReadString(R, buffer);
    WHILE buffer[0] # 0X DO
      IF index # -1 THEN
        i := 0; WHILE (buffer[i] # "#") & (buffer[i] # 0X) DO INC(i) END;
        IF (buffer[i] = "#") & (buffer[i+1] = "#") & (buffer[i+2] = "#") & (buffer[i+3] = "#") THEN
          buffer[i+3] := CHR(30H + index MOD 10);
          buffer[i+2] := CHR(30H + index DIV 10 MOD 10);
          buffer[i+1] := CHR(30H + index DIV 100 MOD 10);
          buffer[i] := CHR(30H + index DIV 1000 MOD 10)
        END
      END;
      Texts.WriteLn(W);
      Texts.Append(Oberon.Log, W.buf);
      Texts.WriteString(W, linePrefix);
      Texts.WriteString(W, buffer);
      Files.ReadInt(R, t);
      IF (t = Byte) OR (t = Bool) OR (t = Char) THEN
        Get(offs, 1, i); INC(offs)
      ELSIF (t = Int) OR (t = Set) OR (t = Real) OR (t = Pointer) OR (t = Record) OR (t = VarParam) OR (t = OpenArrayParam) THEN
        Get(offs, 4, i); INC(offs, 4)
      END;
      IF (t = Byte) OR (t = Int) OR (t = Set) THEN
        IF t = Byte THEN
          Texts.WriteString(W, " (BYTE) = ");
        ELSIF t = Int THEN
          Texts.WriteString(W, " (INTEGER) = ");
        ELSIF t = Set THEN
          Texts.WriteString(W, " (SET) = ");
        END;
        Texts.WriteInt(W, i, 1);
        Texts.WriteString(W, " (0");
        IF t = Byte THEN WriteHex(W, i, 2) ELSE WriteHex(W, i, 8) END;
        Texts.WriteString(W, "H)")
      ELSIF t = Bool THEN
        IF i = 0 THEN
          Texts.WriteString(W, " (BOOLEAN) = FALSE")
        ELSIF i = 1 THEN
          Texts.WriteString(W, " (BOOLEAN) = TRUE")
        ELSE
          Texts.WriteString(W, " (BOOLEAN) = INVALID (");
          Texts.WriteInt(W, i, 1);
          Texts.WriteString(W, ")")
        END
      ELSIF t = Char THEN
        Texts.WriteString(W, " (CHAR) = ");
        Texts.Write(W, 22X);
        Texts.Write(W, CHR(i));
        Texts.Write(W, 22X);
        Texts.WriteString(W, " (");
        Texts.WriteInt(W, i, 1);
        Texts.WriteString(W, ", 0");
        WriteHex(W, i, 2);
        Texts.WriteString(W, "H)")
      ELSIF t = Real THEN
        r := SYSTEM.VAL(REAL, i);
        Texts.WriteString(W, " (REAL) = ");
        Texts.WriteReal(W, r, 15);
        Texts.WriteString(W, " (0");
        WriteHex(W, i, 8);
        Texts.WriteString(W, "R)")
      ELSIF t = Pointer THEN
        IF i = 0 THEN
          Texts.WriteString(W, " (POINTER) = NIL");
        ELSE
          Texts.WriteString(W, " (POINTER) = ");
          Texts.WriteString(W, commandPrefix);
          Texts.WriteString(W, "HeapAddress 0");
          WriteHex(W, i, 8);
          Texts.WriteString(W, "H");
          Get(i, 0, i); (* keep alive *)
        END
      ELSIF t = Proc THEN
        Texts.WriteString(W, " (PROCEDURE)");
        INC(offs, 4)
      ELSIF t = CharArray THEN
        Files.ReadInt(R, i);
        Texts.WriteString(W, " (ARRAY ");
        Texts.WriteInt(W, i, 1);
        Texts.WriteString(W, " OF CHAR) = ");
        Texts.Write(W, 22X);
        Get(offs, 1, j);
        WHILE (i > 0) & (j # 0) DO Texts.Write(W, CHR(j)); DEC(i); INC(offs); Get(offs, 1, j) END;
        Texts.Write(W, 22X);
        WriteByteArray(offs, i, Get)
      ELSIF t = ByteArray THEN
        Files.ReadInt(R, i);
        Texts.WriteString(W, " (ARRAY ");
        Texts.WriteInt(W, i, 1);
        Texts.WriteString(W, " OF BYTE) =");
        WriteByteArray(offs, i, Get)
      ELSIF t = Record THEN
        Texts.WriteString(W, " (VAR RECORD)");
        j := i;
        InspectLoop(R, j, index, linePrefix, Get, commandPrefix);
        i := j - i;
        Get(offs, 4, k); INC(offs, 4);
        Texts.WriteLn(W);
        Texts.Append(Oberon.Log, W.buf);
        Texts.WriteString(W, linePrefix);
        Texts.WriteString(W, buffer);
        Texts.WriteString(W, ".[rest] = ");
        Texts.WriteString(W, commandPrefix);
        Texts.WriteString(W, "TypeRest 0");
        WriteHex(W, k, 8);
        Texts.WriteString(W, "H ");
        Get(k, 4, k);
        Texts.WriteInt(W, i, 1);
        Texts.WriteString(W, " ");
        Texts.WriteInt(W, k - i , 1);
        Texts.WriteString(W, " ");
        k := k - i + j;
        WHILE j < k DO Get(j, 1, i); WriteHex(W, i, 2); INC(j) END
      ELSIF t = VarParam THEN
        Texts.WriteString(W, " (VAR)");
        InspectLoop(R, i, index, linePrefix, Get, commandPrefix);
      ELSIF t = OpenArrayParam THEN
        Get(offs, 4, j); INC(offs, 4);
        Texts.WriteString(W, " (OPEN ARRAY LENGTH ");
        Texts.WriteInt(W, j, 1);
        Texts.WriteString(W, ")");
        oldpos := Files.Pos(R);
        FOR k := 0 TO j-1 DO Files.Set(R, Files.Base(R), oldpos); InspectLoop(R, i, k, linePrefix, Get, commandPrefix) END;
      ELSE
        ASSERT(FALSE)
      END;
      Files.ReadString(R, buffer);
    END;
    Texts.Append(Oberon.Log, W.buf)
  END InspectLoop;

  PROCEDURE InspectHeap*(mname: Modules.ModuleName; offs, doff, skip: INTEGER; VAR F: Files.File; Get: GetDataCallback; commandPrefix: ARRAY OF CHAR);
    VAR i: INTEGER;
      R: Files.Rider;
      name: ARRAY 32 OF CHAR;
  BEGIN
    Texts.WriteLn(W);
    Texts.WriteString(W, "Type descriptor: ");
    Texts.WriteString(W, mname);
    Texts.WriteString(W, "+");
    WriteHex(W, doff, 8);
    Texts.WriteLn(W);
    Files.Set(R, F, 4);
    Files.ReadInt(R, i);
    WHILE (i # -1) & (i # doff) DO Files.ReadInt(R, i); Files.ReadInt(R, i) END;
    IF i = -1 THEN
      Texts.WriteString(W, "Type descriptor not in symbol file");
    ELSE
      Files.ReadInt(R, i);
      Files.Set(R, F, i);
      Texts.WriteString(W, "Type: ");
      Texts.WriteString(W, mname);
      Texts.WriteString(W, "+");
      Files.ReadString(R, name);
      Texts.WriteString(W, name);
      IF skip > 0 THEN
        Texts.WriteLn(W);
        Texts.WriteString(W, "Skipping ");
        Texts.WriteInt(W, skip, 1);
        Texts.WriteString(W, " bytes of base type");
        InspectSkip(R, skip)
      END;
      InspectLoop(R, offs, -1, "", Get, commandPrefix);
    END;
    Texts.Append(Oberon.Log, W.buf)
  END InspectHeap;

  PROCEDURE Module*;
    VAR offs, beg, end, time: INTEGER;
      T: Texts.Text;
      F: Files.File;
      R: Files.Rider;
      S: Texts.Scanner;
      M: Modules.Module;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    IF (S.class = Texts.Char) & (S.c = "^") THEN
      Oberon.GetSelection(T, beg, end, time);
      IF time >= 0 THEN
        Texts.OpenScanner(S, T, beg); Texts.Scan(S);
      END
    END;
    IF S.class = Texts.Name THEN
      Texts.WriteString(W, "ORInspect.Module "); Texts.WriteString(W, S.s);
      M := Modules.root;
      WHILE (M # NIL) & (M.name # S.s) DO M := M.next END;
      IF M = NIL THEN
        Texts.WriteLn(W);
        Texts.WriteString(W, "Module not loaded");
      ELSE
        F := OpenInspectSymbolFile(M);
        IF F = NIL THEN
          Texts.WriteLn(W);
          Texts.WriteString(W, M.name);
          Texts.WriteString(W, ".isy not found");
        ELSE
          Files.Set(R, F, 0);
          Files.ReadInt(R, offs);
          Files.Set(R, F, offs);
          Files.ReadInt(R, offs);
          INC(offs, M.data);
          InspectLoop(R, offs, -1, "", GetData, "ORInspect.");
        END
      END;
      Texts.WriteLn(W); Texts.WriteLn(W);
      Texts.Append(Oberon.Log, W.buf);
    END
  END Module;

  PROCEDURE HeapAddress*;
    VAR offs, i, end, time: INTEGER;
      T: Texts.Text;
      F: Files.File;
      S: Texts.Scanner;
      M: Modules.Module;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    IF (S.class = Texts.Char) & (S.c = "^") THEN
      Oberon.GetSelection(T, i, end, time);
      IF time >= 0 THEN
        Texts.OpenScanner(S, T, i); Texts.Scan(S);
      END
    END;
    IF S.class = Texts.Int THEN
      offs := S.i;
      IF offs = 0 THEN i := 0 ELSE SYSTEM.GET(offs-8, i) END;
      Texts.WriteString(W, "ORInspect.HeapAddress 0"); WriteHex(W, offs, 8);
      Texts.WriteString(W, "H");
      M := Modules.root;
      WHILE (M # NIL) & ((i < M.data) OR (i >= M.code)) DO M := M.next END;
      IF M = NIL THEN
        Texts.WriteLn(W);
        Texts.WriteString(W, "Invalid type descriptor ");
        WriteHex(W, i, 8);
      ELSE
        F := OpenInspectSymbolFile(M);
        IF F = NIL THEN
          Texts.WriteLn(W);
          Texts.WriteString(W, M.name);
          Texts.WriteString(W, ".isy not found");
        ELSE
          InspectHeap(M.name, offs, i - M.data, 0, F, GetData, "ORInspect.");
        END
      END;
      Texts.WriteLn(W); Texts.WriteLn(W);
      Texts.Append(Oberon.Log, W.buf);
    END
  END HeapAddress;

  PROCEDURE KeepHeapAlive*;
    VAR i, beg, end, time: INTEGER;
      T: Texts.Text;
      S: Texts.Scanner;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    IF (S.class = Texts.Char) & (S.c = "^") THEN
      Oberon.GetSelection(T, beg, end, time);
      IF time >= 0 THEN
        Texts.OpenScanner(S, T, beg); Texts.Scan(S);
      END
    END;
    IF S.class = Texts.Int THEN
      keepaliveMax := S.i;
      IF keepaliveMax > 256 THEN keepaliveMax := 256 END;
      FOR i := 0 TO 255 DO keepalive[i] := NIL END
    END
  END KeepHeapAlive;

  PROCEDURE TypeRest*;
    VAR doff, skip, rest, i, j, time: INTEGER;
      ch: CHAR;
      buf: ARRAY 1024 OF BYTE;
      T: Texts.Text;
      F: Files.File;
      S: Texts.Scanner;
      M: Modules.Module;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    IF (S.class = Texts.Char) & (S.c = "^") THEN
      Oberon.GetSelection(T, i, j, time);
      IF time >= 0 THEN
        Texts.OpenScanner(S, T, i); Texts.Scan(S);
      END
    END;
    IF S.class = Texts.Int THEN doff := S.i; Texts.Scan(S) END;
    IF S.class = Texts.Int THEN skip := S.i; Texts.Scan(S) END;
    IF S.class = Texts.Int THEN
      rest := S.i;
      IF rest > 1024 THEN
        Texts.WriteLn(W);
        Texts.WriteString(W, "Rest length too large");
        Texts.WriteLn(W);
      ELSIF S.nextCh = " " THEN
        FOR i := 0 TO rest - 1 DO
          Texts.Read(S, ch);
          ASSERT(("0" <= ch) & (ch <= "9") OR ("A" <= ch) & (ch <= "F"));
          IF ch <= "9" THEN j := ORD(ch) - 30H ELSE j := ORD(ch) - 37H END;
          Texts.Read(S, ch);
          ASSERT(("0" <= ch) & (ch <= "9") OR ("A" <= ch) & (ch <= "F"));
          IF ch <= "9" THEN buf[i] := j * 10H + ORD(ch) - 30H ELSE buf[i] := j * 10H + ORD(ch) - 37H END;
        END;
        M := Modules.root;
        WHILE (M # NIL) & ((doff < M.data) OR (doff >= M.code)) DO M := M.next END;
        IF M = NIL THEN
          Texts.WriteLn(W);
          Texts.WriteString(W, "Invalid type descriptor ");
          WriteHex(W, doff, 8);
        ELSE
          F := OpenInspectSymbolFile(M);
          IF F = NIL THEN
            Texts.WriteLn(W);
            Texts.WriteString(W, M.name);
            Texts.WriteString(W, ".isy not found");
          ELSE
            InspectHeap(M.name, SYSTEM.ADR(buf[0]), doff - M.data, skip, F, GetData, "ORInspect.");
          END
        END;
        Texts.WriteLn(W);
      END;
      Texts.Append(Oberon.Log, W.buf);
    END
  END TypeRest;

BEGIN Texts.OpenWriter(W); keepaliveNext := 0; keepaliveMax := 0;
END ORInspect.
