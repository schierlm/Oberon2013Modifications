MODULE ScriptUtils;
  IMPORT Display, Texts, TextFrames, Viewers, Oberon;

  TYPE
    Line = POINTER TO LineDesc;
    LineDesc = RECORD
      next: Line;
      sortpos: INTEGER;
      content: Texts.Text;
    END;

  VAR W: Texts.Writer;

  (* utility functions *)

  PROCEDURE ScanRawText*(VAR R: Texts.Reader; VAR beg, end: INTEGER);
    VAR ch, ch2: CHAR;
  BEGIN Texts.Read(R, ch);
    WHILE ~R.eot & (ch <= " ") DO Texts.Read(R, ch) END;
    beg := Texts.Pos(R); end := beg; Texts.Read(R, ch2);
    WHILE ~R.eot & (ch # ch2) DO
      end := Texts.Pos(R); Texts.Read(R, ch2)
    END
  END ScanRawText;

  PROCEDURE ExecuteSubCommand*(VAR R: Texts.Reader; T: Texts.Text);
    VAR ch: CHAR; F: TextFrames.Frame;
  BEGIN
    Texts.Read(R, ch);
    WHILE ch <= " " DO Texts.Read(R, ch) END;
    IF (Oberon.Par.frame IS TextFrames.Frame) & (Oberon.Par.frame(TextFrames.Frame).text = T) THEN
      F := Oberon.Par.frame(TextFrames.Frame)
    ELSE
      F := TextFrames.NewText(T, 0)
    END;
    TextFrames.Call(F, Texts.Pos(R) - 1, FALSE)
  END ExecuteSubCommand;

  (* commands *)

  PROCEDURE ClearLog*;
    VAR buf: Texts.Buffer;
  BEGIN NEW(buf); Texts.OpenBuf(buf); Texts.Delete(Oberon.Log, 0, Oberon.Log.len, buf)
  END ClearLog;

  PROCEDURE WriteLog*;
    VAR
      S: Texts.Scanner;
      V: Viewers.Viewer;
      nl, go: BOOLEAN;
      i: INTEGER;
  BEGIN nl := TRUE; go := TRUE;
    Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos);
    WHILE go DO
      Texts.Scan(S);
      IF (S.class = Texts.Char) & (S.c = "\") THEN
        nl := FALSE
      ELSIF (S.class = Texts.Char) & (S.c = "*") THEN
        V := Viewers.This(Display.Width - 10, Display.Height - 10);
        TextFrames.Show(V.dsc.next(TextFrames.Frame), Oberon.Log.len);
      ELSIF S.class = Texts.Int THEN
        FOR i := 1 TO S.i DO Texts.WriteLn(W); END
      ELSIF (S.class = Texts.Name) OR (S.class = Texts.String) THEN
        Texts.WriteString(W, S.s);
        go := FALSE
      ELSE
        go := FALSE
      END
    END;
    IF nl THEN
      Texts.WriteLn(W)
    END;
    Texts.Append(Oberon.Log, W.buf)
  END WriteLog;

  PROCEDURE WriteLogRaw*;
    VAR R: Texts.Reader; beg, end: INTEGER;
  BEGIN
    Texts.OpenReader(R, Oberon.Par.text, Oberon.Par.pos);
    ScanRawText(R, beg, end);
    Texts.Save(Oberon.Par.text, beg, end, W.buf);
    Texts.Append(Oberon.Log, W.buf)
  END WriteLogRaw;

  PROCEDURE Fail*;
    VAR S: Texts.Scanner;
  BEGIN
    Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos);
    Texts.Scan(S);
    IF S.class = Texts.Int THEN
      Oberon.SetRetVal(S.i)
    ELSE
      Oberon.SetRetVal(0FFH)
    END
  END Fail;

  PROCEDURE ExpectFailure*;
    VAR S: Texts.Scanner; rv: INTEGER;
  BEGIN
    Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos);
    Texts.Scan(S);
    IF S.class = Texts.Int THEN
      rv := S.i;
      ExecuteSubCommand(S, Oberon.Par.text);
      IF Oberon.RetVal = rv THEN Oberon.SetRetVal(0) ELSE Oberon.SetRetVal(1) END
    ELSE
      Oberon.SetRetVal(0FFH)
    END
  END ExpectFailure;

  PROCEDURE SortLines*;
    VAR S: Texts.Scanner; T: Texts.Text; beg, end, time, skipcols, i: INTEGER;
      fname: ARRAY 32 OF CHAR; colsep: ARRAY 2 OF CHAR; numeric, backwards, continue: BOOLEAN;
      R, R2: Texts.Reader; ch, ch2: CHAR; buf, buf2: Texts.Buffer; W: Texts.Writer;
      line, prevline, root, rest, nextrest: Line;
  BEGIN numeric := FALSE; backwards := FALSE; skipcols := 0; colsep := "";
    Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos);
    Texts.Scan(S); continue := TRUE; root := NIL;
    WHILE continue DO
      IF (S.class = Texts.Char) & (S.c = "^") THEN
        Oberon.GetSelection(T, beg, end, time);
        IF time >= 0 THEN Texts.OpenScanner(S, T, beg); Texts.Scan(S) END
      ELSIF (S.class = Texts.Char) & (S.c = "#") THEN
        Texts.Scan(S); numeric := TRUE;
      ELSIF (S.class = Texts.Char) & (S.c = "\") THEN
        Texts.Scan(S); backwards := TRUE;
      ELSIF (S.class = Texts.String) & (S.s[0] # 0X) & ((S.s[1] = 0X) OR (S.s[2] = 0X)) THEN
        colsep[0] := S.s[0]; colsep[1] := S.s[1]; Texts.Scan(S)
      ELSIF S.class = Texts.Int THEN
        skipcols := S.i - 1; Texts.Scan(S)
      ELSIF (S.class = Texts.Char) & (S.c = "@") THEN
        Oberon.GetSelection(T, beg, end, time);
        IF end = beg + 1 THEN end := T.len END;
        fname := ""; continue := FALSE;
        IF time < 0 THEN T := NIL END
      ELSIF S.class = Texts.Name THEN
        fname := S.s; continue := FALSE;
        NEW(T); Texts.Open(T, fname); beg := 0; end := T.len
      ELSE
        T := NIL; continue := FALSE;
      END
    END;
    IF T = NIL THEN
      Oberon.SetRetVal(1)
    ELSE
      Texts.OpenReader(R, T, beg);
      NEW(buf); Texts.OpenBuf(buf);
      NEW(buf2); Texts.OpenBuf(buf2);
      Texts.OpenWriter(W);
      (* collect lines *)
      WHILE Texts.Pos(R) < end DO
        Texts.Read(R, ch);
        IF (ch # 9X) & (ch < " ") THEN
          IF Texts.Pos(R) > beg + 1 THEN
            Texts.Delete(T, beg, Texts.Pos(R)-1, buf);
            end := end - buf.len;
            NEW(line); NEW(line.content); Texts.Open(line.content, ""); Texts.Append(line.content, buf);
            line.next := root; root := line
          END;
          Texts.Delete(T, beg, beg+1, buf2); DEC(end);
          Texts.OpenReader(R, T, beg)
        END
      END;
      IF end > beg THEN
        Texts.Delete(T, beg, end, buf);
        NEW(line); NEW(line.content); Texts.Open(line.content, ""); Texts.Append(line.content, buf);
        line.next := root; root := line
      END;
      (* determine insertion position *)
      WHILE line # NIL DO
        IF (skipcols = 0) OR (colsep[0] = 0X) THEN
          line.sortpos := skipcols
        ELSE
          Texts.OpenReader(R, line.content, 0);
          i := skipcols;
          WHILE (i > 0) & ~R.eot DO
            Texts.Read(R, ch);
            WHILE (i > 0) & (ch = colsep[0])& ~R.eot DO
              DEC(i); Texts.Read(R, ch);
              WHILE (ch = colsep[1]) & ~R.eot DO Texts.Read(R, ch) END
            END
          END;
          line.sortpos := Texts.Pos(R) - 1
        END;
        IF numeric THEN
          Texts.OpenScanner(S, line.content, line.sortpos); Texts.Scan(S);
          IF S.class = Texts.Int THEN
            line.sortpos := S.i
          ELSE
            line.sortpos := -1
          END
        END;
        line := line.next
      END;
      (* perform insertion sort *)
      IF root = NIL THEN
        rest := NIL
      ELSE
        rest := root.next; root.next := NIL
      END;
      WHILE rest # NIL DO
        line := root; prevline := NIL; nextrest := rest.next;
        WHILE line # NIL DO
          IF numeric THEN
            continue := rest.sortpos > line.sortpos;
          ELSE
            Texts.OpenReader(R, line.content, line.sortpos);
            Texts.OpenReader(R2, rest.content, rest.sortpos);
            REPEAT Texts.Read(R, ch); Texts.Read(R2, ch2) UNTIL (ch # ch2) OR R.eot OR R2.eot;
            continue := ch2 > ch
          END;
          IF continue # backwards THEN
            prevline := line; line := line.next;
            IF line = NIL THEN prevline.next := rest; rest.next := NIL END
          ELSIF prevline = NIL THEN
            rest.next := root; root := rest; line := NIL
          ELSE
            prevline.next := rest; rest.next := line; line := NIL
          END
        END;
        rest := nextrest
      END;
      (* append lines back *)
      line := NIL; rest := NIL;
      WHILE root # NIL DO
        root.sortpos := root.content.len;
        Texts.Delete(root.content, 0, root.content.len, buf);
        Texts.Insert(T, beg, buf);
        beg := beg + root.sortpos;
        Texts.WriteLn(W); Texts.Insert(T, beg, W.buf); INC(beg);
        root := root.next;
      END;
      IF fname[0] # 0X THEN Texts.Close(T, fname) END
    END
  END SortLines;

BEGIN Texts.OpenWriter(W)
END ScriptUtils.
