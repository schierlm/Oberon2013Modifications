MODULE ScriptBlocks;

  IMPORT Texts, Oberon, ScriptUtils, Script;

  CONST CheckStringValue = "|> ScriptBlocks.";
    MaxDepth = 256;

  VAR CheckString: ARRAY 32 OF CHAR;
    CheckLength, BlocksOpen: INTEGER;
    BlockPositions: ARRAY MaxDepth OF INTEGER;
    BlockIfMatched: ARRAY MaxDepth OF BOOLEAN;

  PROCEDURE Check(name: ARRAY OF CHAR; VAR ok: BOOLEAN);
    VAR R: Texts.Reader; i: INTEGER; ch: CHAR;
  BEGIN i := 0; ok := FALSE;
    WHILE name[i] # 0X DO INC(i) END;
    Texts.OpenReader(R, Oberon.Par.text, Oberon.Par.pos - i - CheckLength);
    Texts.Read(R, ch); i := 0;
    WHILE (ch # 0X) & (ch = CheckString[i]) DO Texts.Read(R, ch); INC(i) END;
    IF i = CheckLength THEN
      i := 0; WHILE (ch # 0X) & (ch = name[i]) DO Texts.Read(R, ch); INC(i) END;
      IF name[i] = 0X THEN ok := TRUE END;
    END;
    IF Script.state # Script.ScriptRunning THEN ok := FALSE END
  END Check;

  PROCEDURE Begin*;
    VAR ok: BOOLEAN;
  BEGIN Check("Begin", ok);
    IF ok THEN
      BlockPositions[BlocksOpen] := Oberon.Par.pos;
      BlockIfMatched[BlocksOpen] := FALSE;
      INC(BlocksOpen)
    ELSE
      Oberon.SetRetVal(1)
    END
  END Begin;

  PROCEDURE Again*;
    VAR ok: BOOLEAN;
  BEGIN Check("Again", ok);
    IF ok & (BlocksOpen > 0) THEN
      BlockIfMatched[BlocksOpen - 1] := FALSE;
      Script.GoToPos(BlockPositions[BlocksOpen - 1])
    ELSE
      Oberon.SetRetVal(1)
    END
  END Again;

  PROCEDURE If*;
    VAR ok, doRun: BOOLEAN; R: Texts.Reader; pos, i, depth: INTEGER; ch: CHAR;
  BEGIN Check("If", ok);
    IF ok & (BlocksOpen > 0) THEN
      IF BlockIfMatched[BlocksOpen - 1] THEN doRun := FALSE
      ELSE
        Texts.OpenReader(R, Oberon.Par.text, Oberon.Par.pos);
        ScriptUtils.ExecuteSubCommand(R, Oberon.Par.text);
        doRun := Oberon.RetVal = 0;
        Oberon.SetRetVal(0);
      END;
      IF doRun THEN
        BlockIfMatched[BlocksOpen - 1] := TRUE
      ELSE
        Texts.OpenReader(R, Oberon.Par.text, Oberon.Par.pos);
        depth := 0; Texts.Read(R, ch);
        WHILE ok DO
          IF R.eot THEN
            Oberon.SetRetVal(1); ok := FALSE
          ELSIF ch = "|" THEN
            Texts.Read(R, ch);
            IF R.eot OR (ch = "|") THEN
              Oberon.SetRetVal(1); ok := FALSE
            ELSIF ch = ">" THEN
              pos := Texts.Pos(R) - 2; i := 1;
              WHILE (i < CheckLength) & (ch = CheckString[i]) DO Texts.Read(R, ch); INC(i) END;
              IF i = CheckLength THEN
                IF (depth = 0) & (ch = "E") THEN (* End *)
                  Script.GoToPos(pos); ok := FALSE
                ELSIF (depth = 0) & (ch = "I") & ~BlockIfMatched[BlocksOpen - 1] THEN (* If *)
                  Script.GoToPos(pos); ok := FALSE
                ELSIF ch = "B" THEN (* Begin *)
                  INC(depth)
                ELSIF ch = "E" THEN (* End *)
                  DEC(depth)
                END
              END
            END
          ELSE
            Texts.Read(R, ch)
          END
        END
      END
    ELSE
      Oberon.SetRetVal(1)
    END
  END If;

  PROCEDURE End*;
    VAR ok: BOOLEAN;
  BEGIN Check("End", ok);
    IF ok & (BlocksOpen > 0) THEN
      DEC(BlocksOpen)
    ELSE
      Oberon.SetRetVal(1)
    END
  END End;

BEGIN
  CheckLength := 0; BlocksOpen := 0; CheckString := CheckStringValue;
  WHILE CheckString[CheckLength] # 0X DO INC(CheckLength) END
END ScriptBlocks.