MODULE ScriptVars;

  IMPORT Display, Texts, TextFrames, Viewers, MenuViewers, Oberon, ScriptUtils;

  CONST StandardMenu = "System.Close System.Copy System.Grow Edit.Search";

  TYPE Variable =  POINTER TO VariableDesc;
    VariableName = ARRAY 32 OF CHAR;
    VariableDesc = RECORD
      next: Variable;
      name: VariableName;
      value: Texts.Text;
      live: BOOLEAN;
    END;

  VAR W: Texts.Writer;
    RootVar: Variable;

  PROCEDURE SkipCaret(VAR S: Texts.Scanner);
    VAR T: Texts.Text; beg, end, time: INTEGER;
  BEGIN
    IF (S.class = Texts.Char) & (S.c = "^") THEN
      Oberon.GetSelection(T, beg, end, time);
      IF time >= 0 THEN Texts.OpenScanner(S, T, beg); Texts.Scan(S) END
    END
  END SkipCaret;

  PROCEDURE FindVar(name: ARRAY OF CHAR) : Variable;
    VAR V : Variable;
  BEGIN V := RootVar;
    WHILE (V # NIL) & (V.name # name) DO V := V.next END;
  RETURN V
  END FindVar;

  PROCEDURE ScanStart(VAR S: Texts.Scanner; needLive, allowSkip: BOOLEAN; VAR V: Texts.Text);
    VAR VV: Variable; T: Texts.Text;
  BEGIN
    Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    IF allowSkip THEN SkipCaret(S) END;
    IF S.class = Texts.Name THEN
      VV := FindVar(S.s);
      IF VV = NIL THEN
        NEW(VV);
        VV.name := S.s;
        VV.next := RootVar;
        VV.live := needLive;
        IF needLive THEN
          VV.value := TextFrames.Text("")
        ELSE
          NEW(T); Texts.Open(T, S.s); VV.value := T
        END;
        RootVar := VV;
      END;
      IF needLive & ~VV.live THEN
        T := TextFrames.Text("");
        Texts.Delete(VV.value, 0, VV.value.len, W.buf);
        Texts.Append(T, W.buf);
        VV.live := TRUE;
        VV.value := T
      END;
      V := VV.value
    ELSE
      V := NIL
    END
  END ScanStart;

  PROCEDURE ScanText(VAR S: Texts.Scanner; allowSkip: BOOLEAN; VAR T: Texts.Text);
    VAR V: Variable;
  BEGIN
    IF allowSkip THEN SkipCaret(S) END;
    IF S.class = Texts.Name THEN
      V := FindVar(S.s); Texts.Scan(S);
      IF V # NIL THEN T := V.value ELSE T := NIL END
    ELSIF S.class = Texts.String THEN
      NEW(T); Texts.Open(T, "");
      Texts.WriteString(W, S.s);
      Texts.Append(T, W.buf); Texts.Scan(S)
    ELSIF S.class = Texts.Int THEN
      NEW(T); Texts.Open(T, "");
      Texts.WriteInt(W, S.i, 1);
      Texts.Append(T, W.buf); Texts.Scan(S)
    ELSE
      T := NIL
    END
  END ScanText;

  PROCEDURE ScanInt(VAR S: Texts.Scanner; allowSkip: BOOLEAN; default: INTEGER): INTEGER;
    VAR res: INTEGER; T: Texts.Text; S2: Texts.Scanner;
  BEGIN res := default;
    IF allowSkip THEN SkipCaret(S) END;
    IF S.class = Texts.Int THEN
      res := S.i; Texts.Scan(S)
    ELSE
      ScanText(S, allowSkip, T);
      IF T # NIL THEN
        Texts.OpenScanner(S2, T, 0);
        Texts.Scan(S2);
        IF S2.class = Texts.Int THEN
          res := S2.i
        END
      END
    END
  RETURN res
  END ScanInt;

  PROCEDURE Clear(T: Texts.Text);
    VAR buf: Texts.Buffer;
  BEGIN
    IF T.len # 0 THEN
      NEW(buf); Texts.OpenBuf(buf); Texts.Delete(T, 0, T.len, buf)
    END
  END Clear;

  PROCEDURE Set*;
    VAR src, dst: Texts.Text; S: Texts.Scanner;
  BEGIN ScanStart(S, FALSE, TRUE, dst); Texts.Scan(S); ScanText(S, TRUE, src);
    IF (src # NIL) & (dst # NIL) THEN
      Clear(dst);
      Texts.Save(src, 0, src.len, W.buf);
      Texts.Append(dst, W.buf)
    ELSE
      Oberon.SetRetVal(1)
    END
  END Set;

  PROCEDURE SetChars*;
    VAR dst: Texts.Text; S: Texts.Scanner; ch: INTEGER;
  BEGIN ScanStart(S, FALSE, TRUE, dst);
    IF dst # NIL THEN
      Clear(dst); Texts.Scan(S);
      ch := ScanInt(S, TRUE, 999);
      WHILE ch # 999 DO Texts.Write(W, CHR(ch)); ch := ScanInt(S, TRUE, 999) END;
      Texts.Append(dst, W.buf)
    ELSE
      Oberon.SetRetVal(1)
    END
  END SetChars;

  PROCEDURE SetRaw*;
    VAR dst: Texts.Text; beg, end: INTEGER; S: Texts.Scanner;
  BEGIN ScanStart(S, FALSE, FALSE, dst); ScriptUtils.ScanRawText(S, beg, end);
    IF dst # NIL THEN
      Clear(dst);
      Texts.Save(Oberon.Par.text, beg, end, W.buf);
      Texts.Append(dst, W.buf)
    ELSE
      Oberon.SetRetVal(1)
    END
  END SetRaw;

  PROCEDURE Load*;
    VAR name, dst: Texts.Text; S: Texts.Scanner;
  BEGIN ScanStart(S, FALSE, TRUE, dst); Texts.Scan(S); ScanText(S, TRUE, name);
    IF (name # NIL) & (dst # NIL) THEN
      Texts.OpenScanner(S, name, 0); Texts.Scan(S);
      IF S.class = Texts.Name THEN
        Texts.Open(name, S.s);
        Clear(dst);
        Texts.Save(name, 0, name.len, W.buf);
        Texts.Append(dst, W.buf)
      ELSE
        Oberon.SetRetVal(1)
      END
    ELSE
      Oberon.SetRetVal(1)
    END
  END Load;

  PROCEDURE Store*;
    VAR src, name: Texts.Text; S: Texts.Scanner;
  BEGIN ScanStart(S, FALSE, TRUE, src); Texts.Scan(S); ScanText(S, TRUE, name);
    IF (src # NIL) & (name # NIL) THEN
      Texts.OpenScanner(S, name, 0); Texts.Scan(S);
      IF S.class = Texts.Name THEN
        Texts.Close(src, S.s)
      ELSE
        Oberon.SetRetVal(1)
      END
    ELSE
      Oberon.SetRetVal(1)
    END
  END Store;

  PROCEDURE Insert*;
      VAR src, dst: Texts.Text; pos: INTEGER; S: Texts.Scanner;
  BEGIN ScanStart(S, FALSE, TRUE, dst); Texts.Scan(S); ScanText(S, TRUE, src); pos := ScanInt(S, TRUE, 999999);
    IF pos < 0 THEN pos := pos + dst.len + 1 END;
    IF (src # NIL) & (dst # NIL) & (pos >= 0) & (pos <= dst.len) THEN
      Texts.Save(src, 0, src.len, W.buf);
      Texts.Insert(dst, pos, W.buf);
    ELSE
      Oberon.SetRetVal(1)
    END
  END Insert;

  PROCEDURE Cut*;
      VAR src, dst: Texts.Text; beg, end: INTEGER; S: Texts.Scanner;
  BEGIN ScanStart(S, FALSE, TRUE, dst); Texts.Scan(S); ScanText(S, TRUE, src);
    beg := ScanInt(S, TRUE, 999999); end := ScanInt(S, TRUE, 999999);
    IF beg < 0 THEN beg := beg + src.len + 1 END;
    IF end < 0 THEN end := end + src.len + 1 END;
    IF (src # NIL) & (dst # NIL) & (beg >= 0) & (beg <= end) & (end <= src.len) THEN
      Texts.Delete(src, beg, end, W.buf);
      Clear(dst);
      Texts.Append(dst, W.buf)
    ELSE
      Oberon.SetRetVal(1)
    END
  END Cut;

  PROCEDURE Copy*;
      VAR src, dst: Texts.Text; beg, end: INTEGER; S: Texts.Scanner;
  BEGIN ScanStart(S, FALSE, TRUE, dst); Texts.Scan(S); ScanText(S, TRUE, src);
    beg := ScanInt(S, TRUE, 999999); end := ScanInt(S, TRUE, 999999);
    IF beg < 0 THEN beg := beg + src.len + 1 END;
    IF end < 0 THEN end := end + src.len + 1 END;
    IF (src # NIL) & (dst # NIL) & (beg >= 0) & (beg <= end) & (end <= src.len) THEN
      Texts.Save(src, beg, end, W.buf);
      Clear(dst);
      Texts.Append(dst, W.buf)
    ELSE
      Oberon.SetRetVal(1)
    END
  END Copy;

  PROCEDURE Length*;
    VAR src, dst: Texts.Text; S: Texts.Scanner;
  BEGIN ScanStart(S, FALSE, TRUE, dst); Texts.Scan(S); ScanText(S, TRUE, src);
    IF (src # NIL) & (dst # NIL) THEN
      Clear(dst);
      Texts.WriteInt(W, src.len, 1);
      Texts.Append(dst, W.buf)
    ELSE
      Oberon.SetRetVal(1)
    END
  END Length;


  PROCEDURE CharCodeAt*;
    VAR src, dst: Texts.Text; pos: INTEGER; S: Texts.Scanner; R: Texts.Reader; ch: CHAR;
  BEGIN ScanStart(S, FALSE, TRUE, dst); Texts.Scan(S); ScanText(S, TRUE, src); pos := ScanInt(S, TRUE, 999999);
    IF pos < 0 THEN pos := pos + src.len + 1 END;
    IF (src # NIL) & (dst # NIL) & (pos >= 0) & (pos <= src.len) THEN
      Texts.OpenReader(R, src, pos);
      Texts.Read(R, ch);
      Clear(dst);
      Texts.WriteInt(W, ORD(ch), 1);
      Texts.Append(dst, W.buf)
    ELSE
      Oberon.SetRetVal(1)
    END
  END CharCodeAt;

  PROCEDURE DoFind(src, needle: Texts.Text; VAR pos: INTEGER);
  VAR R, RN: Texts.Reader; ch, chn: CHAR; found: BOOLEAN;
  BEGIN
    (* this may be optimized, e.g. Boyer-Moore algorithm *)
    found := FALSE;
    WHILE ~found & (pos <= src.len - needle.len) DO
      Texts.OpenReader(R, src, pos);
      Texts.OpenReader(RN, needle, 0);
      REPEAT Texts.Read(R, ch); Texts.Read(RN, chn) UNTIL (ch # chn) OR RN.eot;
      IF RN.eot THEN found := TRUE ELSE INC(pos) END
    END;
    IF ~found THEN pos := -1 END
  END DoFind;

  PROCEDURE Find*;
    VAR src, needle, dst: Texts.Text; S: Texts.Scanner; pos: INTEGER;
  BEGIN ScanStart(S, FALSE, TRUE, dst); Texts.Scan(S); ScanText(S, TRUE, src); pos := ScanInt(S, TRUE, 99999);ScanText(S, TRUE, needle);
    IF pos < 0 THEN pos := pos + src.len + 1 END;
    IF (src # NIL) & (dst # NIL) & (needle # NIL) & (needle.len > 0) & (pos >= 0) & (pos <= src.len) THEN
      DoFind(src, needle, pos);
      Clear(dst);
      Texts.WriteInt(W, pos, 1);
      Texts.Append(dst, W.buf)
    ELSE
      Oberon.SetRetVal(1)
    END
  END Find;

  PROCEDURE Replace*;
    VAR dst, needle, replacement: Texts.Text; S: Texts.Scanner;
      pos, maxcount: INTEGER; buf: Texts.Buffer;
  BEGIN ScanStart(S, FALSE, TRUE, dst); Texts.Scan(S);
    pos := ScanInt(S, TRUE, 99999); ScanText(S, TRUE, needle);
    maxcount := ScanInt(S, TRUE, 0); ScanText(S, TRUE, replacement);
    IF pos < 0 THEN pos := pos + dst.len + 1 END;
    IF (dst # NIL) & (needle # NIL) & (replacement # NIL) & (needle.len > 0) & (pos >= 0) & (pos <= dst.len) & (maxcount > 0) THEN
      NEW(buf); Texts.OpenBuf(buf);
      DoFind(dst, needle, pos);
      WHILE (maxcount > 0) & (pos # -1) DO
        Texts.Delete(dst, pos, pos + needle.len, buf);
        Texts.Save(replacement, 0, replacement.len, W.buf);
        Texts.Insert(dst, pos, W.buf);
        pos := pos + replacement.len;
        DoFind(dst, needle, pos)
      END
    ELSE
      Oberon.SetRetVal(1)
    END
  END Replace;

  PROCEDURE NewMenu (prefix, varname, commands: ARRAY OF CHAR): TextFrames.Frame;
    VAR name: ARRAY 64 OF CHAR; i,j: INTEGER; F: TextFrames.Frame;
  BEGIN i := 0; j := 0;
    WHILE prefix[i] # 0X DO name[i] := prefix[i]; INC(i) END;
    WHILE varname[j] # 0X DO name[i] := varname[j]; INC(i); INC(j) END;
    F := TextFrames.NewMenu(name, commands)
  RETURN F
  END NewMenu;

  PROCEDURE ShowViewer(VAR S: Texts.Scanner; prefix: ARRAY OF CHAR; T: Texts.Text);
  VAR V: Viewers.Viewer; F: TextFrames.Frame; X, Y, beg, end: INTEGER;
  BEGIN
    Oberon.AllocateSystemViewer(Oberon.Par.vwr.X, X, Y);
    F := TextFrames.NewText(T, 0);
    V := MenuViewers.New(NewMenu(prefix, S.s, StandardMenu), F, TextFrames.menuH, X, Y);
    Texts.Scan(S);
    IF S.class = Texts.Int THEN beg := S.i; Texts.Scan(S) END;
    IF S.class = Texts.Int THEN
      IF beg < 0 THEN beg := beg + T.len + 1 END;
      end := S.i;
      IF end < 0 THEN end := end + T.len + 1 END;
      IF (beg >= 0) & (beg <= end) & (end <= T.len) THEN
      TextFrames.SetSelection(F, beg, end)
      END
    END
  END ShowViewer;

  PROCEDURE ShowCopy*;
    VAR src: Texts.Text; S: Texts.Scanner; T: Texts.Text;
  BEGIN ScanStart(S, FALSE, TRUE, src);
    IF src # NIL THEN
      T := TextFrames.Text("");
      Texts.Save(src, 0, src.len, W.buf);
      Texts.Append(T, W.buf);
      ShowViewer(S, "ScriptVars.Copy.", T)
    ELSE
      Oberon.SetRetVal(1)
    END
  END ShowCopy;

  PROCEDURE ShowLive*;
    VAR src: Texts.Text; S: Texts.Scanner;
  BEGIN ScanStart(S, TRUE, TRUE, src);
    IF src # NIL THEN
      ShowViewer(S, "ScriptVars.Live.", src)
    ELSE
      Oberon.SetRetVal(1)
    END
  END ShowLive;

  PROCEDURE CaptureLog*;
    VAR dst: Texts.Text; logpos: INTEGER; S: Texts.Scanner;
  BEGIN ScanStart(S, FALSE, FALSE, dst);
    IF dst # NIL THEN
      logpos := Oberon.Log.len;
      ScriptUtils.ExecuteSubCommand(S, Oberon.Par.text);
      Clear(dst);
      IF Oberon.Log.len > logpos THEN
        Texts.Save(Oberon.Log, logpos, Oberon.Log.len, W.buf);
        Texts.Append(dst, W.buf);
      END
    ELSE
      Oberon.SetRetVal(1)
    END
  END CaptureLog;

  PROCEDURE CaptureError*;
    VAR dst: Texts.Text; S: Texts.Scanner;
  BEGIN ScanStart(S, FALSE, FALSE, dst);
    IF dst # NIL THEN
      ScriptUtils.ExecuteSubCommand(S, Oberon.Par.text);
      Clear(dst);
      Texts.WriteInt(W, Oberon.RetVal, 1);
      Texts.Append(dst, W.buf);
      Oberon.SetRetVal(0)
    ELSE
      Oberon.SetRetVal(1)
    END
  END CaptureError;

  PROCEDURE CaptureViewer*;
    VAR dst, vname: Texts.Text; S: Texts.Scanner; dupe, close: BOOLEAN;
    V: Viewers.Viewer; T: Texts.Text; X: INTEGER;
    R, R2: Texts.Reader; ch, ch2: CHAR;
    fil, bot, alt, max, menu, content: Display.Frame;
  BEGIN ScanStart(S, FALSE, TRUE, dst); Texts.Scan(S); close := FALSE;
    IF (S.class = Texts.Char) & (S.c = "-") THEN
      close := TRUE; Texts.Scan(S);
    END; ScanText(S, TRUE, vname); V := NIL; dupe := FALSE;
    IF (dst # NIL) & (vname # NIL) THEN
      X := 0;
      fil := NIL;
      Viewers.Locate(X, 0, fil, bot, alt, max);
      WHILE fil # NIL DO
        WHILE bot # fil DO
          IF bot IS MenuViewers.Viewer THEN
            menu := bot.dsc;
            content := bot.dsc.next;
            IF (menu IS TextFrames.Frame) & (content IS TextFrames.Frame) THEN
              T := menu(TextFrames.Frame).text;
              Texts.OpenReader(R, T, 0); Texts.OpenReader(R2, vname, 0);
              REPEAT Texts.Read(R, ch); Texts.Read(R2, ch2) UNTIL (ch # ch2) OR (R2.eot);
              IF R2.eot THEN
                IF V = NIL THEN V := bot(Viewers.Viewer) ELSE dupe := TRUE END
              END
            END
          END;
          bot := bot.next
        END;
        X := fil.X + fil.W+1;
        fil := NIL;
        Viewers.Locate(X, 0, fil, bot, alt, max);
      END
    END;
    IF (V # NIL) & ~dupe THEN
      Clear(dst);
      T := V.dsc.next(TextFrames.Frame).text;
      Texts.Save(T, 0, T.len, W.buf);
      Texts.Append(dst, W.buf);
      IF close THEN Viewers.Close(V) END
    ELSE
      Oberon.SetRetVal(1)
    END
  END CaptureViewer;

  PROCEDURE Compare*;
    VAR src, other: Texts.Text; S, S2: Texts.Scanner; run: BOOLEAN; op: CHAR;
    R, R2: Texts.Reader; ch, ch2: CHAR; val: INTEGER;
  BEGIN ScanStart(S, FALSE, FALSE, src); Texts.Scan(S);
    IF src = NIL THEN
      op := 0X
    ELSIF (S.class = Texts.Char) & (S.c = "=") THEN
      op := S.c; Texts.Scan(S); ScanText(S, FALSE, other);
      IF other = NIL THEN op := 0X END
    ELSIF (S.class = Texts.Char) & ((S.c = "<") OR (S.c = ">") OR (S.c = "#")) THEN
      op := S.c; Texts.Scan(S); val := ScanInt(S, FALSE, 0);
    ELSE op := 0X END;
    IF (S.class = Texts.Char) & (S.c = "-") THEN run := FALSE
    ELSIF (S.class = Texts.Char) & (S.c = "+") THEN run := TRUE;
    ELSE op := 0X END;
    IF op # 0X THEN
      IF (op = "=") THEN
        Texts.OpenReader(R, src, 0);
        Texts.OpenReader(R2, other, 0);
        REPEAT Texts.Read(R, ch); Texts.Read(R2, ch2) UNTIL (ch # ch2) OR R.eot OR R2.eot;
        IF ~R.eot OR ~R2.eot THEN run := ~run END;
      ELSE
        Texts.OpenScanner(S2, src, 0); Texts.Scan(S2);
        IF S2.class = Texts.Int THEN
          IF (op = ">") & (S2.i <= val) THEN run := ~run
          ELSIF (op = "<") & (S2.i >= val) THEN run := ~run
          ELSIF (op = "#") & (S2.i = val) THEN run := ~run
          END
        ELSE op := 0X END
      END
    END;
    IF op # 0X THEN
      IF run THEN ScriptUtils.ExecuteSubCommand(S, Oberon.Par.text) END
    ELSE
      Oberon.SetRetVal(1)
    END
  END Compare;

  PROCEDURE DoExpand(log: Texts.Text);
    VAR R: Texts.Reader; logpos, rpos, ppos, i: INTEGER; markFound, errFound: BOOLEAN; ch: CHAR;
      name: VariableName; V: Variable;
  BEGIN
    logpos := log.len;
    Texts.OpenReader(R, Oberon.Par.text, Oberon.Par.pos);
    markFound := FALSE; errFound := FALSE; rpos := Texts.Pos(R);
    WHILE ~markFound & ~errFound & ~R.eot DO
      Texts.Read(R, ch);
      IF ch = "%" THEN
        ppos := Texts.Pos(R) - 1;
        Texts.Read(R, ch);
        IF ch = "~" THEN
          Texts.Save(Oberon.Par.text, rpos, ppos, W.buf);
          Texts.Append(log, W.buf);
          markFound := TRUE
        ELSIF ch = "%" THEN
          Texts.Save(Oberon.Par.text, rpos, ppos + 1, W.buf);
          Texts.Append(log, W.buf);
        ELSE
          Texts.Save(Oberon.Par.text, rpos, ppos, W.buf);
          Texts.Append(log, W.buf);
          i := 0;
          WHILE (ch # "%") & (i < 31) DO name[i] := ch; Texts.Read(R, ch); INC(i) END;
          name[i] := 0X;
          IF ch = "%" THEN V := FindVar(name); ELSE V := NIL END;
          IF V # NIL THEN
            Texts.Save(V.value, 0, V.value.len, W.buf)
          ELSE
            errFound := TRUE; Texts.WriteLn(W); Texts.WriteString(W, "Variable not found"); Texts.WriteLn(W);
          END; Texts.Append(log, W.buf)
        END;
        rpos := Texts.Pos(R);
      END
    END;
    IF markFound THEN
      Texts.WriteLn(W); Texts.Append(log, W.buf);
      Texts.OpenReader(R, log, logpos);
      ScriptUtils.ExecuteSubCommand(R, log)
    ELSIF ~errFound THEN
      Texts.WriteLn(W); Texts.WriteString(W, "%~ not found"); Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf);
      Oberon.SetRetVal(1)
    ELSE
      Oberon.SetRetVal(1)
    END
  END DoExpand;

  PROCEDURE Expand*;
  BEGIN DoExpand(TextFrames.Text(""))
  END Expand;

  PROCEDURE ExpandLog*;
  BEGIN Texts.WriteString(W, "Executing: "); Texts.Append(Oberon.Log, W.buf); DoExpand(Oberon.Log)
  END ExpandLog;

BEGIN Texts.OpenWriter(W); RootVar := NIL;
END ScriptVars.