MODULE EmulatorFrames;

  IMPORT SYSTEM, Display, Viewers, Oberon, MenuViewers, TextFrames, EmulatorCPU, EmulatorCore;

  TYPE Frame* = POINTER TO FrameDesc;
    FrameDesc* = RECORD (Display.FrameDesc)
      e*: EmulatorCore.Emulator;
      backColor, xorColor, outColor: INTEGER;
    END;

    UpdateMsg = RECORD (Display.FrameMsg)
      e: EmulatorCore.Emulator;
      minX, maxX, minY, maxY: INTEGER
    END;

  PROCEDURE UpdateDisplay(F: Frame; minX, maxX, minY, maxY: INTEGER);
    TYPE Pattern = RECORD res1, res2, width, height: BYTE; data: ARRAY 16 OF INTEGER END;
    VAR x, y, i: INTEGER; p: Pattern;
  BEGIN
    IF F.e.stopped THEN
      Display.ReplConst(F.outColor, F.X, F.Y, F.W, F.H, Display.replace)
    ELSE
      IF maxX >= F.W DIV 32 * 32 THEN maxX := F.W DIV 32 * 32 - 1 END;
      IF maxY >= F.H THEN maxY := F.H - 1 END;
      minX := minX DIV 32 * 32; maxX := maxX DIV 32 * 32 + 31;
      Display.ReplConst(F.backColor, F.X+minX, F.Y+minY, maxX-minX+1, maxY-minY+1, Display.replace);
      x := minX; p.width := 32;
      WHILE x <= maxX DO
        y := minY;
        WHILE y <= maxY DO
          p.height := maxY - y + 1;
          IF p.height > 16 THEN p.height := 16 END;
          FOR i := 0 TO p.height - 1 DO
            SYSTEM.GET(SYSTEM.ADR(F.e.mem.vid) + (y+i) * 128 + x DIV 8, p.data[i]);
          END;
          Display.CopyPattern(F.xorColor, SYSTEM.ADR(p.width), F.X + x, F.Y + y, Display.invert);
          INC(y, 16)
        END;
        INC(x, 32)
      END
    END
  END UpdateDisplay;

  PROCEDURE Restore(F: Frame);
  BEGIN Oberon.RemoveMarks(F.X, F.Y, F.W, F.H);
    Display.ReplConst(F.outColor, F.X, F.Y, F.W, F.H, Display.replace); (*clear*)
    UpdateDisplay(F, 0, F.e.width - 1, 0, F.e.height - 1);
  END Restore;

  PROCEDURE Handle(F: Display.Frame; VAR M: Display.FrameMsg);
    VAR F1: Frame;
      x, y: INTEGER;
  BEGIN
    CASE F OF Frame:
      CASE M OF
        Oberon.InputMsg:
          IF M.id = Oberon.track THEN
            x := M.X - F.X; y := M.Y - F.Y;
            IF ~(F.e.stopped) & (x >= 0) & (x < F.e.width) & (y >= 0) & (y < F.e.height) THEN
              EmulatorCore.SetMouse(F.e, x, y, M.keys);
              IF M.keys # {} THEN Oberon.PassFocus(Viewers.This(F.X, F.Y)) END
            ELSE
              Oberon.DrawMouseArrow(M.X, M.Y)
            END
          ELSIF M.id = Oberon.consume THEN
            EmulatorCore.AddKey(F.e, M.ch)
          END
        | UpdateMsg:
          IF M.e = F.e THEN
            UpdateDisplay(F, M.minX, M.maxX, M.minY, M.maxY)
          END
        | Oberon.CopyMsg:
          Oberon.RemoveMarks(F.X, F.Y, F.W, F.H); NEW(F1); F1^ := F^; M.F := F1
        | MenuViewers.ModifyMsg:
          IF (M.Y # F.Y) OR (M.H # F.H) THEN F.Y := M.Y; F.H := M.H; Restore(F) END
        | Oberon.ControlMsg:
          IF M.id = Oberon.neutralize THEN
            EmulatorCore.AddKey(F.e, 1BX)
          ELSIF M.id = Oberon.mark THEN
            EmulatorCore.AddKey(F.e, 1AX)
          END
      END
    END
  END Handle;

  PROCEDURE Open*(e: EmulatorCore.Emulator; backColor, xorColor, outColor: INTEGER; diskName: ARRAY OF CHAR);
    VAR F: Frame; V: Viewers.Viewer; X, Y: INTEGER;
  BEGIN NEW(F); F.e := e; F.handle := Handle;
    F.backColor := backColor; F.xorColor := xorColor; F.outColor := outColor;
    Oberon.AllocateUserViewer(Oberon.Par.vwr.X, X, Y);
    V := MenuViewers.New(
      TextFrames.NewMenu(diskName, "System.Close System.Copy System.Grow Emulator.Break Emulator.Reset Emulator.Stop"),
      F, TextFrames.menuH, X, Y)
  END Open;

  PROCEDURE DisplayNotify*(e: EmulatorCore.Emulator; minX, maxX, minY, maxY: INTEGER);
    VAR UM: UpdateMsg;
  BEGIN UM.e := e; UM.minX := minX; UM.maxX := maxX;
    UM.minY := minY; UM.maxY := maxY;
    Viewers.Broadcast(UM)
  END DisplayNotify;

END EmulatorFrames.
