MODULE OnScreenKeyboard;
IMPORT Display, Input, Texts, Viewers, Oberon, TextFrames, MenuViewers;

  CONST FileName = "OnScreenKeyboard.Text";
    StandardMenu = "System.Close System.Copy System.Grow";

  PROCEDURE Handle* (F: Display.Frame; VAR M: Display.FrameMsg);
    VAR R: Texts.Reader; handled, addSpace: BOOLEAN;
      pos: INTEGER; ks1, ks2: SET; ch1,ch2: CHAR;
  BEGIN handled := FALSE;
    CASE M OF Oberon.InputMsg:
      handled := TRUE;
      IF M.id = Oberon.track THEN
        Oberon.DrawMouseArrow(M.X, M.Y);
        IF (M.keys = {0}) OR (M.keys={1}) OR (M.keys={2}) THEN
          TextFrames.TrackWord(F(TextFrames.Frame), M.X, M.Y, pos, ks1);
          IF ks1 = M.keys THEN
            addSpace := FALSE;
            Texts.OpenReader(R, F(TextFrames.Frame).text, pos); Texts.Read(R, ch1); Texts.Read(R, ch2);
            IF (ch1 = "M") & ((ch2 = "L") OR (ch2 = "M") OR (ch2 = "R")) THEN
              ks1 := {}; ks2 := {};
              WHILE (ch2 = "L") OR (ch2 = "M") OR (ch2 = "R") OR (ch2 = "+") DO
                IF ch2 = "L" THEN INCL(ks1, 2)
                ELSIF ch2 = "M" THEN INCL(ks1, 1)
                ELSIF ch2 = "R" THEN INCL(ks1, 0)
                ELSE ks2 := ks1 END;
                Texts.Read(R, ch2);
              END;
              IF ks2 = {} THEN Input.OverrideMouseKeys(ks1, ks2) ELSE Input.OverrideMouseKeys(ks2, ks1) END
            ELSE
              IF (ch1 # " ") & (ch2 = " ") THEN
                IF (ch1 >= "A") & (ch1 <= "Z") & (M.keys # {0}) THEN ch1 := CHR(ORD(ch1) - ORD("A") + ORD("a"))
                ELSIF (ch1 >= "a") & (ch1 <= "z") & (M.keys = {0}) THEN ch1 := CHR(ORD(ch1) - ORD("a") + ORD("A")) END;
                IF M.keys = {1} THEN addSpace := TRUE END
              ELSIF (ch1 = "T") & (ch2 = "A") THEN ch1 := 9X
              ELSIF (ch1 = "R") & (ch2 = "E") THEN ch1 := 0DX
              ELSIF (ch1 = "B") & (ch2 = "K") THEN ch1 := 8X
              ELSIF (ch1 = "D") & (ch2 = "E") THEN ch1 := 7FX
              ELSIF (ch1 = "E") & (ch2 = "S") THEN ch1 := 1BX
              ELSIF (ch1 = "F") & (ch2 = "1") THEN ch1 := 1AX
              ELSIF M.keys = {1} THEN ch1 := 9X
              ELSIF M.keys = {0} THEN ch1 := 0DX
              ELSE ch1 := " " END;
              Input.InjectChar(addSpace, ch1)
            END
          END
        END
      END
    END;
    IF ~handled THEN TextFrames.Handle(F, M) END
  END Handle;

  PROCEDURE Show*;
    VAR T: Texts.Text;
      F: TextFrames.Frame;
      V: Viewers.Viewer;
      X, Y: INTEGER;
      beg, end, time: LONGINT;
  BEGIN NEW(F);
    Oberon.AllocateSystemViewer(Oberon.Par.vwr.X, X, Y);
    TextFrames.Open(F, Handle, TextFrames.Text(FileName), 0, Display.black, TextFrames.left, TextFrames.right, TextFrames.top, TextFrames.bot, TextFrames.lsp);
    V := MenuViewers.New(TextFrames.NewMenu(FileName, StandardMenu), F, TextFrames.menuH, X, 100);
  END Show;

BEGIN
END OnScreenKeyboard.