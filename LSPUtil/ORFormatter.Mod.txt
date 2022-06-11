MODULE ORFormatter;
  IMPORT Texts, Oberon, LSPhConstants, LSPhORS, LSPhORP, LSPUtil;

  TYPE Token = POINTER TO TokenDesc;
    TokenDesc = RECORD
      next: Token;
      beg, end, value, outdent, indent: INTEGER;
    END;

  VAR W: Texts.Writer;
    tokenRoot, prevComment: Token;

    nextLineIndent: INTEGER;
    eatWS, lastEmpty, currEmpty, currSpace: BOOLEAN;

  PROCEDURE RemoveTrailingWhitespace(VAR T: Texts.Text; maxcount: INTEGER; VAR pos, posdelta: INTEGER);
    VAR R: Texts.Reader; buf: Texts.Buffer; ch: CHAR; i: INTEGER;
  BEGIN i := 0;
    REPEAT
      INC(i); Texts.OpenReader(R, T, pos - i); Texts.Read(R, ch)
    UNTIL ch # " "; DEC(i);
    IF (maxcount >= 0) & (i > maxcount) THEN i := maxcount END;
    IF i # 0 THEN
      NEW(buf); Texts.OpenBuf(buf);
      Texts.Delete(T, pos - i, pos, buf);
      DEC(pos, i); DEC(posdelta, i);
    END
  END RemoveTrailingWhitespace;

  PROCEDURE UpdateToken(VAR T: Texts.Text; VAR posdelta: INTEGER; beg, end: INTEGER; VAR T1: Token);
    VAR ws, pos, i: INTEGER; buf: Texts.Buffer;
  BEGIN
    ws := T1.value DIV 10;
    IF currEmpty THEN
      pos := beg + posdelta;
      RemoveTrailingWhitespace(T, T1.outdent * 2, pos, posdelta);
      IF (ws = 3) & ~lastEmpty THEN
        Texts.Write(W, 0DX); lastEmpty := TRUE;
        Texts.Insert(T, pos, W.buf);
        INC(posdelta)
      END
    ELSIF ws = 1 THEN
      IF ~currSpace THEN
        Texts.Write(W, " "); currSpace := TRUE;
        Texts.Insert(T, beg + posdelta, W.buf);
        INC(posdelta)
      END
    ELSIF ws # 9 THEN
      IF currSpace THEN
        NEW(buf); Texts.OpenBuf(buf);
        Texts.Delete(T, beg+posdelta - 1, beg + posdelta, buf);
        currSpace := FALSE; DEC(posdelta)
      END;
      IF ws # 0 THEN
        Texts.Write(W, 0DX); pos := 1; lastEmpty := FALSE;
        IF ws = 3 THEN
          Texts.Write(W, 0DX); INC(pos); lastEmpty := TRUE
        END;
        FOR i := 0 TO 2 * (nextLineIndent - T1.outdent) - 1 DO
          Texts.Write(W, " "); INC(pos)
        END;
        Texts.Insert(T, beg + posdelta, W.buf);
        INC(posdelta, pos)
      END
    END;
    currEmpty := FALSE; currSpace := FALSE; ws := T1.value MOD 10;
    nextLineIndent := nextLineIndent + T1.indent - T1.outdent;
    IF ws = 1 THEN
      Texts.Write(W, " "); currSpace := TRUE;
      Texts.Insert(T, end + posdelta, W.buf);
      INC(posdelta)
    END;
    eatWS := ws = 0
  END UpdateToken;

  PROCEDURE CollapseWhitespace(VAR T: Texts.Text; VAR posDelta: INTEGER; beg, end: INTEGER) : BOOLEAN;
    VAR R: Texts.Reader; ch, ch0: CHAR; len: INTEGER; buf: Texts.Buffer; found: BOOLEAN;
  BEGIN len := 0;
    Texts.OpenReader(R, T, beg + posDelta); Texts.Read(R, ch); ch0 := ch;
    WHILE (len < end - beg) & ((ch <= " ") & (ch # 0DX)) DO INC(len); Texts.Read(R, ch) END;
    found := len # 0;
    IF (len > 1) OR ((len = 1) & (ch0 # " ")) THEN
      NEW(buf); Texts.OpenBuf(buf);
      Texts.Delete(T, beg + posDelta, beg + posDelta + len, buf);
      Texts.Write(W, " "); Texts.Insert(T, beg+posDelta, W.buf);
      DEC(posDelta, len - 1)
    END
  RETURN found
  END CollapseWhitespace;

  PROCEDURE UpdateWhitespace(VAR T: Texts.Text; VAR posdelta: INTEGER; beg, end: INTEGER);
    VAR pos, i, cnt: INTEGER; wsFound: BOOLEAN; R: Texts.Reader; buf: Texts.Buffer; ch: CHAR;
  BEGIN NEW(buf); Texts.OpenBuf(buf);
    pos := beg + posdelta; wsFound := CollapseWhitespace(T, posdelta, beg, end);
    IF eatWS & wsFound THEN
      Texts.Delete(T, pos, pos + 1, buf); DEC(posdelta); wsFound := FALSE
    END;
    eatWS := FALSE;
    WHILE pos < end + posdelta DO
      IF wsFound THEN
        IF currEmpty OR currSpace THEN
          Texts.Delete(T, pos, pos + 1, buf); DEC(posdelta);
        ELSE
          INC(pos)
        END;
        wsFound := FALSE
      ELSE
        Texts.OpenReader(R, T, pos); Texts.Read(R, ch);
        ASSERT(ch = 0DX);
        IF currEmpty THEN
          RemoveTrailingWhitespace(T, -1, pos, posdelta); INC(pos)
        ELSIF currSpace THEN
          Texts.Delete(T, pos - 1, pos, buf); DEC(posdelta)
        ELSE
          INC(pos)
        END;
        lastEmpty := currEmpty; currEmpty := TRUE; currSpace := FALSE;
        IF nextLineIndent > 0 THEN
          i := nextLineIndent * 2;
          Texts.OpenReader(R, T, pos); Texts.Read(R, ch);
          WHILE (i > 0) & (ch = " ") DO INC(pos); DEC(i); Texts.Read(R, ch) END;
          cnt := i;
          WHILE i > 0 DO Texts.Write(W, " "); DEC(i) END;
          Texts.Insert(T, pos, W.buf);
          INC(pos, cnt); INC(posdelta, cnt)
        END;
        wsFound := CollapseWhitespace(T, posdelta, pos - posdelta, end);
      END
    END
  END UpdateWhitespace;

  PROCEDURE FormatCallback(tag, beg, end, value: INTEGER);
    VAR T: Token;
  BEGIN
    IF tag = LSPhConstants.FormatToken THEN
      IF (prevComment # NIL) & (prevComment # tokenRoot) THEN prevComment := NIL END;
      IF (prevComment # NIL) & (value DIV 10 = 3) THEN DEC(value, 10) END;
      NEW(T); T.next := tokenRoot; tokenRoot := T;
      T.outdent := 0; T.indent := 0;
      T.beg := beg; T.end := end; T.value := value;
    ELSIF tag = LSPhConstants.FormatTokenUpdate THEN
      IF (prevComment # NIL) & (value DIV 10 = 3) THEN DEC(value, 10) END;
      tokenRoot.value := value
    ELSIF tag = LSPhConstants.IndentNextLine THEN
      INC(tokenRoot.indent);
    ELSIF tag = LSPhConstants.OutdentThisLine THEN
      INC(tokenRoot.outdent);
    ELSIF tag = LSPhConstants.OutdentThisLineAndComment THEN
      IF prevComment # NIL THEN INC(prevComment.outdent) ELSE INC(tokenRoot.outdent) END
    ELSIF tag = LSPhConstants.TokenIsComment THEN
      prevComment := tokenRoot;
    END
  END FormatCallback;

  PROCEDURE FormatFile(VAR T: Texts.Text; beg: INTEGER; name: ARRAY OF CHAR);
    VAR T1, T2: Token; pos, posdelta: INTEGER;
  BEGIN
    tokenRoot := NIL; prevComment := NIL;
    LSPhORS.SetMode(LSPhConstants.FormatCallback, FormatCallback);
    LSPhORP.AnalyzeText(T, beg);
    T1 := tokenRoot; tokenRoot := NIL;
    WHILE T1 # NIL DO (* reverse list *)
      T2 := T1.next;
      T1.next := tokenRoot;
      tokenRoot := T1;
      T1 := T2
    END;
    posdelta := 0; pos := beg; T1 := tokenRoot;
    lastEmpty := TRUE; currEmpty := TRUE; currSpace := FALSE;
    eatWS := FALSE; nextLineIndent := 0;
    WHILE T1 # NIL DO
      IF pos < T1.beg THEN
        UpdateWhitespace(T, posdelta, pos, T1.beg);
      END;
      UpdateToken(T, posdelta, T1.beg, T1.end, T1);
      pos := T1.end;
      T1 := T1.next
    END;
    IF (LSPhORS.errcnt = 0) & (name[0] # 0X) THEN
      Texts.Close(T, name);
      Texts.WriteString(W, name);
      Texts.WriteLn(W);
      Texts.Append(Oberon.Log, W.buf)
    END
  END FormatFile;

  PROCEDURE Format*;
    VAR T: Texts.Text;
      S: Texts.Scanner;
      beg, end, time: INTEGER;
  BEGIN
    Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos);
    LSPUtil.ParseArgs(S, FormatFile)
  END Format;

BEGIN Texts.OpenWriter(W)
END ORFormatter.
