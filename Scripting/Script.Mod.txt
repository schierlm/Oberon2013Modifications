MODULE Script;
  IMPORT Kernel, Texts, TextFrames, Oberon;

  CONST
    ScriptStopped = 0;
    ScriptRunning* = 1;
    ScriptWaitGC = 2;
    ScriptFailed = 3;

  VAR label: ARRAY 32 OF CHAR;
    state*, gcWaitAllocated, jumpPos: INTEGER;
    scriptFrame: TextFrames.Frame;
    scriptReader: Texts.Reader;
    gcWaitTask: Oberon.Task;

  PROCEDURE Collect*;
  BEGIN Oberon.Collect(1);
    IF state = ScriptRunning THEN state := ScriptWaitGC END
  END Collect;

  PROCEDURE Continue;
    VAR W: Texts.Writer; ch: CHAR; lpos, i: INTEGER;
  BEGIN
    state := ScriptRunning;
    WHILE state = ScriptRunning DO
      IF label[0] # 0X THEN
        Texts.OpenReader(scriptReader, scriptFrame.text, 0);
        Texts.Read(scriptReader, ch); lpos := 0;
        WHILE ~scriptReader.eot & (lpos = 0) DO
          IF ch = ":" THEN
            lpos := Texts.Pos(scriptReader); i := 0;
            Texts.Read(scriptReader, ch);
            WHILE (ch = ":") OR (label[i] = ch) DO
              IF ch = ":" THEN i := 0 ELSE INC(i) END;
              Texts.Read(scriptReader, ch)
            END;
            IF (ch = "|") & (label[i] = 0X) THEN
              Texts.Read(scriptReader, ch);
              IF ch # ">" THEN lpos := 0 END
            ELSE
              lpos := 0
            END;
          END;
          Texts.Read(scriptReader, ch)
        END;
        IF lpos # 0 THEN
          Texts.OpenReader(scriptReader, scriptFrame.text, lpos)
        END;
        label := ""
      ELSIF jumpPos # 0 THEN
        Texts.OpenReader(scriptReader, scriptFrame.text, jumpPos);
        jumpPos := 0
      END;
      Texts.Read(scriptReader, ch);
      IF scriptReader.eot THEN
        state := ScriptStopped
      ELSIF ch = "|" THEN
        Texts.Read(scriptReader, ch);
        IF scriptReader.eot OR (ch = "|") THEN
          state := ScriptStopped;
        ELSIF ch = ">" THEN
          Texts.Read(scriptReader, ch);
          WHILE ch <= " " DO Texts.Read(scriptReader, ch) END;
          TextFrames.Call(scriptFrame, Texts.Pos(scriptReader) - 1, FALSE);
          IF Oberon.RetVal # 0 THEN
            Texts.OpenWriter(W);
            Texts.WriteString(W, "Command exited with error code ");
            Texts.WriteInt(W, Oberon.RetVal, 7);
            Texts.WriteLn(W);
            Texts.Append(Oberon.Log, W.buf);
            state := ScriptFailed
          END
        END
      END
    END;
    IF state = ScriptWaitGC THEN
      Texts.OpenWriter(W); (* calls NEW *)
      Texts.WriteString(W, "Waiting for gc ...");
      Texts.Append(Oberon.Log, W.buf);
      gcWaitAllocated := Kernel.allocated;
      Oberon.Install(gcWaitTask);
    ELSE
      state := ScriptStopped;
      Texts.OpenReader(scriptReader, Oberon.Log, Oberon.Log.len); (* free old scriptReader *)
      scriptFrame := NIL;
    END
  END Continue;

  PROCEDURE GCWait;
    VAR W: Texts.Writer;
  BEGIN
    IF (state = ScriptWaitGC) & (Kernel.allocated < gcWaitAllocated) THEN
      Texts.OpenWriter(W);
      Texts.WriteString(W, " done");
      Texts.WriteLn(W);
      Texts.Append(Oberon.Log, W.buf);
      Oberon.Remove(gcWaitTask);
      Continue();
    ELSE
      Oberon.Collect(0);
    END
  END GCWait;

  PROCEDURE Run*;
    VAR W: Texts.Writer;
  BEGIN
    IF state # ScriptStopped THEN
      Texts.OpenWriter(W);
      Texts.WriteString(W, "Cannot run Script while another Script is running");
      Texts.WriteLn(W);
      Texts.Append(Oberon.Log, W.buf);
    ELSE
      Texts.OpenReader(scriptReader, Oberon.Par.text, Oberon.Par.pos);
      IF (Oberon.Par.frame IS TextFrames.Frame) & (Oberon.Par.frame(TextFrames.Frame).text = Oberon.Par.text) THEN
        scriptFrame := Oberon.Par.frame(TextFrames.Frame)
      ELSE
        scriptFrame := TextFrames.NewText(Oberon.Par.text, 0)
      END;
      label := ""; jumpPos := 0;
      Continue()
    END
  END Run;

  PROCEDURE GoTo*;
    VAR S: Texts.Scanner;
  BEGIN
    Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos);
    Texts.Scan(S);
    IF S.class = Texts.Name THEN
      label := S.s
    ELSE
      Oberon.SetRetVal(1)
    END
  END GoTo;

  PROCEDURE GoToPos*(pos: INTEGER);
  BEGIN jumpPos := pos
  END GoToPos;

  PROCEDURE RunFile*;
    VAR S: Texts.Scanner; T: Texts.Text; beg, end, time: INTEGER; W: Texts.Writer;
  BEGIN
    IF state # ScriptStopped THEN
      Texts.OpenWriter(W);
      Texts.WriteString(W, "Cannot run Script while another Script is running");
      Texts.WriteLn(W);
      Texts.Append(Oberon.Log, W.buf);
    ELSE
      Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos);
      Texts.Scan(S);
      IF (S.class = Texts.Char) & (S.c = "^") THEN
        Oberon.GetSelection(T, beg, end, time);
        IF time >= 0 THEN Texts.OpenScanner(S, T, beg); Texts.Scan(S) END
      END;
      label := ""; jumpPos := 0;
      IF (S.class = Texts.Char) & (S.c = "@") THEN
        Oberon.GetSelection(T, beg, end, time);
        IF time < 0 THEN T := NIL END
      ELSIF S.class = Texts.Name THEN
        T := TextFrames.Text(S.s); beg := 0; Texts.Scan(S);
        IF S.class = Texts.Name THEN label := S.s END
      ELSE
        T := NIL
      END;
      IF T # NIL THEN
        Texts.OpenReader(scriptReader, T, beg);
        IF (Oberon.Par.frame IS TextFrames.Frame) & (Oberon.Par.frame(TextFrames.Frame).text = T) THEN
          scriptFrame := Oberon.Par.frame(TextFrames.Frame)
        ELSE
          scriptFrame := TextFrames.NewText(T, 0)
        END;
        Continue()
      ELSE
        Oberon.SetRetVal(1)
      END
    END
  END RunFile;

BEGIN
  gcWaitTask := Oberon.NewTask(GCWait, 100);
END Script.
