MODULE ORHighlighter;
  IMPORT Fonts, Texts, Oberon, LSPhConstants, LSPhORS, LSPhORP, LSPUtil;

  CONST
    SynExportedType = 16; SynExportedConstant = 17; SynExportedVariable = 18;
    SynExportedRecordField = 19; SynExportedProcedure = 20; SynExportedCommandProcedure = 21;
    SynWrittenVariable = 22; SynWrittenParameter = 23;
    SynWrittenRecordField = 24; SynExportOperator = 25;

    NumHighlightings = 32;

  TYPE
    SyntaxElement = RECORD
      beg, end, type: INTEGER;
    END;

    Highlighting = RECORD
      name: ARRAY 32 OF CHAR;
      fnt: Fonts.Font;
      col: INTEGER;
    END;

  VAR W: Texts.Writer; T: Texts.Text;
    hilite: ARRAY 32 OF Highlighting;
    currElem, lastElem, lastExport: SyntaxElement;

  PROCEDURE DoHighlight(VAR elem: SyntaxElement);
  BEGIN
    Texts.ChangeLooks(T, elem.beg, elem.end, {0, 1}, hilite[elem.type].fnt, hilite[elem.type].col, 0)
  END DoHighlight;

  PROCEDURE HighlightCallback(tag, beg, end, value: INTEGER);
  BEGIN
    IF tag = LSPhConstants.SyntaxElement THEN
      lastElem := currElem;
      currElem.beg := beg; currElem.end := end; currElem.type := value;
      DoHighlight(currElem);
    ELSIF tag = LSPhConstants.NameExported THEN
      IF currElem.type = LSPhConstants.SynOperator THEN
        currElem.type := SynExportOperator; DoHighlight(currElem)
      END;
      IF lastElem.type = LSPhConstants.SynType THEN
        lastElem.type := SynExportedType; DoHighlight(lastElem)
      ELSIF lastElem.type = LSPhConstants.SynConstant THEN
        lastElem.type := SynExportedConstant; DoHighlight(lastElem)
      ELSIF lastElem.type = LSPhConstants.SynVariable THEN
        lastElem.type := SynExportedVariable; DoHighlight(lastElem)
      ELSIF lastElem.type = LSPhConstants.SynRecordField THEN
        lastElem.type := SynExportedRecordField; DoHighlight(lastElem)
      ELSIF lastElem.type = LSPhConstants.SynProcedure THEN
        lastElem.type := SynExportedProcedure; DoHighlight(lastElem)
      END;
      lastExport := lastElem
    ELSIF tag = LSPhConstants.ForwardPointer THEN
      currElem.type := LSPhConstants.SynType; DoHighlight(currElem)
    ELSIF tag = LSPhConstants.CommandExported THEN
      IF lastExport.type = SynExportedProcedure THEN
        lastExport.type := SynExportedCommandProcedure; DoHighlight(lastExport)
      END
    ELSIF tag = LSPhConstants.VarModified THEN
      IF currElem.type = LSPhConstants.SynVariable THEN
        currElem.type := SynWrittenVariable; DoHighlight(currElem)
      ELSIF currElem.type = LSPhConstants.SynParameter THEN
        currElem.type := SynWrittenParameter; DoHighlight(currElem)
      ELSIF lastElem.type = LSPhConstants.SynRecordField THEN
        currElem.type := SynWrittenRecordField; DoHighlight(currElem)
      END;
    END
  END HighlightCallback;

  PROCEDURE HighlightFile(VAR T1: Texts.Text; beg: INTEGER; name: ARRAY OF CHAR);
    VAR T2: Texts.Text;
  BEGIN T := T1;
    currElem.type := 0; lastElem.type := 0; lastExport.type := 0;
    NEW(T2); Texts.Open(T2, "");
    Texts.Save(T1, 0, T1.len, W.buf);
    Texts.Append(T2, W.buf);
    LSPhORS.SetMode(LSPhConstants.HighlightCallback, HighlightCallback);
    LSPhORP.AnalyzeText(T2, beg);
    IF (LSPhORS.errcnt = 0) & (name[0] # 0X) THEN
      Texts.Close(T, name);
      Texts.WriteString(W, name);
      Texts.WriteLn(W);
      Texts.Append(Oberon.Log, W.buf)
    END
  END HighlightFile;

  PROCEDURE InitHighlights;
    VAR i: INTEGER; R: Texts.Reader; H: Highlighting; ch: CHAR;
  BEGIN Texts.OpenReader(R, T, 0);
    FOR i := 0 TO NumHighlightings - 1 DO hilite[i].col := Oberon.CurCol; hilite[i].fnt := Oberon.CurFnt END;
    Texts.Read(R, ch);
    WHILE ~R.eot DO
      IF ch = "[" THEN
        Texts.Read(R, ch); H.fnt := R.fnt; H.col := R.col; i := 0;
        WHILE ~R.eot & (i < 31) & (ch # "]") DO
          H.name[i] := ch; Texts.Read(R, ch); INC(i)
        END;
        H.name[i] := 0X;
        FOR i := 0 TO NumHighlightings - 1 DO
          IF (hilite[i].name[0] # 0X) & (hilite[i].name = H.name) THEN
            hilite[i].fnt := H.fnt; hilite[i].col := H.col
          END
        END
      END;
      Texts.Read(R, ch)
    END
  END InitHighlights;

  PROCEDURE Highlight*;
    VAR S: Texts.Scanner;
  BEGIN
    Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    IF S.class = Texts.Name THEN
      NEW(T); Texts.Open(T, S.s);
      InitHighlights();
      LSPUtil.ParseArgs(S, HighlightFile);
      T := NIL
    END
  END Highlight;

  PROCEDURE Init;
    VAR i: INTEGER;
  BEGIN
    FOR i := 0 TO NumHighlightings - 1 DO hilite[i].name := "" END;
    hilite[LSPhConstants.SynOperator].name := "Operator";
    hilite[LSPhConstants.SynType].name := "Type";
    hilite[LSPhConstants.SynKeyword].name := "Keyword";
    hilite[LSPhConstants.SynString].name := "String";
    hilite[LSPhConstants.SynComment].name := "Comment";
    hilite[LSPhConstants.SynConstant].name := "Constant";
    hilite[LSPhConstants.SynUndefined].name := "Undefined";
    hilite[LSPhConstants.SynModule].name := "Module";
    hilite[LSPhConstants.SynVariable].name := "Variable";
    hilite[LSPhConstants.SynParameter].name := "Parameter";
    hilite[LSPhConstants.SynRecordField].name := "RecordField";
    hilite[LSPhConstants.SynProcedure].name := "Procedure";
    hilite[SynExportedType].name := "ExportedType";
    hilite[SynExportedConstant].name := "ExportedConstant";
    hilite[SynExportedVariable].name := "ExportedVariable";
    hilite[SynExportedRecordField].name := "ExportedRecordField";
    hilite[SynExportedProcedure].name := "ExportedProcedure";
    hilite[SynExportedCommandProcedure].name := "ExportedCommandProcedure";
    hilite[SynWrittenVariable].name := "WrittenVariable";
    hilite[SynWrittenParameter].name := "WrittenParameter";
    hilite[SynWrittenRecordField].name := "WrittenRecordField";
    hilite[SynExportOperator].name := "ExportOperator";
  END Init;

BEGIN Texts.OpenWriter(W); Init
END ORHighlighter.
