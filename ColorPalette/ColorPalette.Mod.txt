MODULE ColorPalette;
  IMPORT Display, Viewers, Oberon, MenuViewers, TextFrames;

  CONST Menu = "System.Close  System.Copy  System.Grow";

  PROCEDURE DrawPalette(F: Display.Frame);
    VAR x, y, w, h, ww, hh: INTEGER;
  BEGIN hh := LSL(1, Display.Depth DIV 2);
    ww := LSL(1, Display.Depth - Display.Depth DIV 2);
    w := F.W DIV ww; h := F.H DIV hh;
    Display.ReplConst(Display.black, F.X, F.Y, F.W, F.H, Display.replace);
    FOR x := 0 TO ww - 1 DO
      FOR y := 0 TO hh - 1 DO
        Display.ReplConst((hh - 1 - y) * ww + x, F.X + x * w, F.Y + y * h, w, h, Display.replace);
      END
    END
  END DrawPalette;

  PROCEDURE Handler(F: Display.Frame; VAR M: Display.FrameMsg);
    VAR F0: Display.Frame;
  BEGIN
    IF M IS Oberon.InputMsg THEN
      IF M(Oberon.InputMsg).id = Oberon.track THEN
        Oberon.DrawMouseArrow(M(Oberon.InputMsg).X, M(Oberon.InputMsg).Y)
      END
    ELSIF M IS MenuViewers.ModifyMsg THEN
      F.Y := M(MenuViewers.ModifyMsg).Y; F.H := M(MenuViewers.ModifyMsg).H; DrawPalette(F)
    ELSIF M IS Oberon.ControlMsg THEN
      IF M(Oberon.ControlMsg).id = Oberon.neutralize THEN Oberon.RemoveMarks(F.X, F.Y, F.W, F.H) END
    ELSIF M IS Oberon.CopyMsg THEN
      NEW(F0); F0^ := F^; M(Oberon.CopyMsg).F := F0
    END
  END Handler;

  PROCEDURE Draw*;
    VAR V: Viewers.Viewer; X, Y: INTEGER; F: Display.Frame;
  BEGIN
    NEW(F); F.handle := Handler;
    Oberon.AllocateUserViewer(Oberon.Par.vwr.X, X, Y);
    V := MenuViewers.New(TextFrames.NewMenu("ColorPalette", Menu), F, TextFrames.menuH, X, Y)
  END Draw;

END ColorPalette.