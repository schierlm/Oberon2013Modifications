MODULE HostTransfer;
  IMPORT SYSTEM, Kernel, FileDir, Files, Texts, Oberon;

  CONST BufSize = 512;
    OpWriteToHost = 20001H; OpWriteBuffer = 20002H;
    OpReadFromHost = 20003H; OpRunOnHost = 20004H; OpReadBuffer = 20005H;

  TYPE Buffer = RECORD
      op, len: INTEGER;
      data: ARRAY BufSize OF BYTE;
    END;

  VAR
    hwAddr: INTEGER;
    fileName: FileDir.FileName;
    W: Texts.Writer;

  PROCEDURE ParseArgs(VAR buffer: Buffer): BOOLEAN;
    VAR S: Texts.Scanner;
      T: Texts.Text;
      beg, i, time: INTEGER;
      done: BOOLEAN; ch, ch2, cq: CHAR;
  BEGIN done := FALSE; T := Oberon.Par.text;
    Texts.OpenScanner(S, T, Oberon.Par.pos);
    Texts.Scan(S);
    IF (S.class = Texts.Char) & (S.c = "^") THEN
      Oberon.GetSelection(T, beg, i, time);
      IF time >= 0 THEN Texts.OpenScanner(S, T, beg); Texts.Scan(S) END
    END;
    IF (S.class = Texts.Char) & (S.c = "-") THEN
      fileName := ""; done := TRUE
    ELSIF (S.class = Texts.Name) THEN
      fileName := S.s; done := TRUE
    END;
    IF done THEN
      ch := S.nextCh; i := 0;
      WHILE ~S.eot & (ch <= " ") DO Texts.Read(S, ch) END;
      beg := Texts.Pos(S) - 1;
      IF (ch = "'") OR (ch = 22X) THEN
        REPEAT
          Texts.Read(S, ch2); buffer.data[i] := ORD(ch2); INC(i);
          done := ch = ch2
        UNTIL done OR S.eot OR (i = BufSize); DEC(i)
      ELSIF (ch = "\") THEN
        Texts.Read(S, cq); Texts.Read(S, ch);
        IF (ch = "'") OR (ch = 22X) THEN
          REPEAT
            Texts.Read(S, ch2); buffer.data[i] := ORD(ch2); INC(i);
            done := (i > 2) & (ch2 = "\") & (buffer.data[i-2] = ORD(cq)) & (buffer.data[i-3] = ORD(ch))
          UNTIL done OR S.eot OR (i = BufSize); DEC(i, 3)
        ELSE
          done := FALSE
        END
      ELSE
        Texts.OpenScanner(S, T, beg); Texts.Scan(S);
        IF (S.class = Texts.Name) THEN
          WHILE (S.s[i] # 0X) DO buffer.data[i] := ORD(S.s[i]); INC(i) END
        ELSE
          done := FALSE
        END
      END
    END;
    IF done THEN buffer.len := i;
      WHILE i < BufSize DO buffer.data[i] := 0; INC(i) END
    END;
    RETURN done
  END ParseArgs;

  PROCEDURE WriteLog(VAR buffer: Buffer);
   VAR i: INTEGER;
  BEGIN
    FOR i := 0 TO buffer.len - 1 DO
      IF buffer.data[i] = 0AH THEN buffer.data[i] := 0DH END;
      Texts.Write(W, CHR(buffer.data[i]))
    END
  END WriteLog;

  PROCEDURE Call(VAR buffer: Buffer);
  BEGIN
    IF hwAddr = 0 THEN
      Texts.WriteString(W, "HostTransfer not supported"); buffer.len := -1
    ELSE
      SYSTEM.PUT(hwAddr, SYSTEM.ADR(buffer));
      IF buffer.len # 0 THEN WriteLog(buffer); buffer.len := -1 END
    END;
    (* len is now either 0 or -1 *)
  END Call;

  PROCEDURE CopyToHost*;
    VAR buffer: Buffer; F: Files.File; R: Files.Rider;
  BEGIN buffer.op := OpWriteToHost; F := NIL;
    IF ParseArgs(buffer) & (fileName[0] # 0X) THEN
      F := Files.Old(fileName)
    END;
    IF F # NIL THEN
      Texts.WriteString(W, "Sending "); Texts.WriteString(W, fileName);
      Texts.WriteString(W, ": ");
      Call(buffer);
      IF buffer.len = 0 THEN
        buffer.op := OpWriteBuffer;
        Files.Set(R, F, 0);
        Files.ReadByte(R, buffer.data[0]);
        buffer.len := 1;
        WHILE (buffer.len # -1) & (~R.eof) DO
          Files.ReadByte(R, buffer.data[buffer.len]);
          INC(buffer.len);
          IF (buffer.len = BufSize) THEN Call(buffer) END
        END;
        IF buffer.len > 0 THEN Call(buffer) END;
        IF buffer.len = 0 THEN Call(buffer) END;
        IF buffer.len = 0 THEN Texts.WriteString(W, "done.") END
      END;
      Files.Close(F);
      Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
    END
  END CopyToHost;

  PROCEDURE ReadOp(VAR buffer: Buffer);
    VAR F: Files.File; R: Files.Rider; i: INTEGER; ok: BOOLEAN;
  BEGIN ok := FALSE;
    IF ParseArgs(buffer) THEN
      IF (fileName[0] # 0X) THEN
        F := Files.New(fileName);
        IF F # NIL THEN
          Texts.WriteString(W, "Receiving "); Texts.WriteString(W, fileName);
          ok := TRUE
        END;
      ELSE
        Texts.WriteString(W, "Logging output");
        F := NIL; ok := TRUE
      END
    END;
    IF ok THEN
      Texts.WriteString(W, ": ");
      Call(buffer);
      IF buffer.len = 0 THEN
        buffer.op := OpReadBuffer;
        IF F = NIL THEN
          Texts.WriteString(W, "Output follows"); Texts.WriteLn(W); Texts.WriteLn(W)
        ELSE
          Files.Set(R, F, 0)
        END;
        REPEAT
          buffer.len := BufSize;
          SYSTEM.PUT(hwAddr, SYSTEM.ADR(buffer));
          IF F = NIL THEN
            WriteLog(buffer)
          ELSE
            Files.WriteBytes(R, buffer.data, buffer.len)
          END
        UNTIL buffer.len = 0;
        Texts.WriteString(W, "done.")
      END;
      IF F # NIL THEN
        IF buffer.len = 0 THEN Files.Register(F) ELSE Files.Close(F) END
      END;
      Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
    END
  END ReadOp;

  PROCEDURE CopyFromHost*;
    VAR buffer: Buffer;
  BEGIN buffer.op := OpReadFromHost; ReadOp(buffer)
  END CopyFromHost;

  PROCEDURE RunCommand*;
    VAR buffer: Buffer;
  BEGIN buffer.op := OpRunOnHost; ReadOp(buffer)
  END RunCommand;

BEGIN Texts.OpenWriter(W);
  hwAddr := Kernel.ToHardwareID("vHTx");
  SYSTEM.PUT(Kernel.hwEnumerator, hwAddr);
  SYSTEM.GET(Kernel.hwEnumerator, hwAddr)
END HostTransfer.
