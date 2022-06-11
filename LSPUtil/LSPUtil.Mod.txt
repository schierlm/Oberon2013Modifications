MODULE LSPUtil;

  IMPORT Texts, Oberon, LSPhConstants, LSPhORS, LSPhORP;

  TYPE FileCallback = PROCEDURE(VAR T: Texts.Text; beg: INTEGER; name: ARRAY OF CHAR);

  VAR W: Texts.Writer;

  PROCEDURE CheckErrors(name: ARRAY OF CHAR);
  BEGIN
    IF LSPhORS.errcnt # 0 THEN
      IF name[0] # 0X THEN
        Texts.WriteString(W, name);
        Texts.WriteString(W, ": ")
      END;
      Texts.WriteString(W, "Parsing file failed - result may be incorrect");
      Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
    END
  END CheckErrors;

  PROCEDURE ParseArgs* (VAR S: Texts.Scanner; callback: FileCallback);
    VAR T: Texts.Text;
      beg, end, time: INTEGER;
  BEGIN
    Texts.Scan(S);
    IF S.class = Texts.Char THEN
      IF S.c = "@" THEN
        Oberon.GetSelection(T, beg, end, time);
        IF time >= 0 THEN callback(T, beg, ""); CheckErrors("") END
      ELSIF S.c = "^" THEN
        Oberon.GetSelection(T, beg, end, time);
        IF time >= 0 THEN
          Texts.OpenScanner(S, T, beg); Texts.Scan(S);
          IF S.class = Texts.Name THEN
            NEW(T); Texts.Open(T, S.s);
            IF T.len > 0 THEN callback(T, beg, S.s); CheckErrors(S.s) END
          END
        END
      END
    ELSE
      WHILE S.class = Texts.Name DO
        NEW(T); Texts.Open(T, S.s);
        IF T.len > 0 THEN callback(T, beg, S.s); CheckErrors(S.s)
        ELSE Texts.WriteString(W, S.s); Texts.WriteString(W, " not found");
          Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
        END;
        Texts.Scan(S)
      END
    END; T := NIL;
  END ParseArgs;

  PROCEDURE CompileFile(VAR T: Texts.Text; beg: INTEGER; name: ARRAY OF CHAR);
  BEGIN
    LSPhORS.SetMode(LSPhConstants.CompileSymbolFile, NIL);
    LSPhORP.AnalyzeText(T, beg)
  END CompileFile;

  PROCEDURE CompileSymbols*;
    VAR S: Texts.Scanner;
  BEGIN
    Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos);
    ParseArgs(S, CompileFile)
  END CompileSymbols;

BEGIN Texts.OpenWriter(W)
END LSPUtil.
