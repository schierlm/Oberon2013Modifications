MODULE Pixelizr;
  IMPORT SYSTEM, Display, Viewers, Input, Texts, Graphics, Oberon, TextFrames, MenuViewers,
   GraphicFrames, PixelizrObjects;

  CONST
   Menu = "System.Close  System.Copy  System.Grow  Pixelizr.Apply  Pixelizr.Disable";
   MenuD = "System.Close  System.Copy  System.Grow  Pixelizr.Apply  Pixelizr.Enable | Draw.Delete  Draw.Ticks  Draw.Restore";

  TYPE
    Frame = POINTER TO FrameDesc;

    FrameDesc* = RECORD (GraphicFrames.FrameDesc)
        parent: GraphicFrames.Frame;
        picture: Graphics.Object;
        enabled: BOOLEAN;
      END;

  VAR
    W: Texts.Writer;

  PROCEDURE Pixelize(F: Frame; x0, y0: INTEGER; k0: SET);
    VAR x1, y1, col: INTEGER;
      k1: SET;
  BEGIN k1 := k0;
    IF (k0 = {2}) OR (k0 = {0}) THEN
      DEC(x0, (x0-F.x) MOD 16); DEC(y0, (y0-F.y) MOD 16);
      WHILE (k1 # {}) DO
        Oberon.FadeMouse;
        IF (x0 - F.x > 0) & (x0 - F.x < 33*16) & (y0 - F.y > 0) & (y0 - F.y < 33*16) THEN
          IF k0 = {2} THEN col := Display.white ELSE col := Display.black END;
          PixelizrObjects.MakeFill(col, x0 - F.x, y0 - F.y, F);
        END;
        REPEAT Input.Mouse(k1, x1, y1);
          DEC(x1, (x1-F.x) MOD 4); DEC(y1, (y1-F.y) MOD 4);
          Oberon.DrawMouse(GraphicFrames.Crosshair, x1, y1);
          DEC(x1, (x1-F.x) MOD 16); DEC(y1, (y1-F.y) MOD 16);
        UNTIL (k1 = {}) OR (x1 # x0) OR (y1 # y0);
        x0 := x1; y0 := y1
      END;
      Oberon.FadeMouse
    ELSIF k0 = {1} THEN
      REPEAT Input.Mouse(k1, x1, y1);
        DEC(x1, (x1-F.x) MOD 4); DEC(y1, (y1-F.y) MOD 4);
        Oberon.DrawMouse(GraphicFrames.Crosshair, x1, y1)
      UNTIL  k1 = {};
      Oberon.FadeMouse; INC(F.Xg, x1-x0); INC(F.Yg, y1-y0); GraphicFrames.Restore(F)
    END
  END Pixelize;

  PROCEDURE ChangeMenu(newMenu: ARRAY OF CHAR);
    VAR t: Texts.Text; buf: Texts.Buffer;
  BEGIN
    t := Oberon.Par.vwr.dsc(TextFrames.Frame).text;
    NEW(buf); Texts.OpenBuf(buf); Texts.Delete(t, 0, t.len, buf);
    Texts.WriteString(W, "Pixelizr | ");
    Texts.WriteString(W, newMenu); Texts.Append(t, W.buf);
  END ChangeMenu;

  PROCEDURE Disable*;
  VAR F: Frame;
  BEGIN
    ChangeMenu(MenuD);
    F := Oberon.Par.vwr.dsc.next(Frame);
    F.enabled := FALSE;
  END Disable;

  PROCEDURE Enable*;
  VAR F: Frame;
  BEGIN
    ChangeMenu(Menu);
    F := Oberon.Par.vwr.dsc.next(Frame);
    F.enabled := TRUE;
  END Enable;

  PROCEDURE Handle*(G: Display.Frame; VAR M: Display.FrameMsg);
    VAR x, y: INTEGER;
      handled: BOOLEAN;
  BEGIN
    handled := FALSE;
    CASE G OF Frame:
      IF G.enabled THEN
        CASE M OF Oberon.InputMsg:
          IF M.id = Oberon.track THEN
            x := M.X - (M.X - G.x) MOD 4; y := M.Y - (M.Y - G.y) MOD 4;
            IF M.keys # {} THEN Pixelize(G, x, y, M.keys); handled := TRUE END
          END
        END
      END
    END;
    IF ~handled THEN GraphicFrames.Handle(G, M) END
  END Handle;

  PROCEDURE Open*;
    VAR X, Y, i: INTEGER;
      s: SET;
      GF: GraphicFrames.Frame;
      G: Graphics.Graph;
      F: Frame;
      V: Viewers.Viewer;
      T: Graphics.Object;
  BEGIN
    GF := GraphicFrames.Focus();
    IF (GF # NIL) & (GF.marked) THEN
      X := GF.mark.x; Y := GF.mark.y;
      GraphicFrames.Deselect(GF);
      GraphicFrames.Defocus(GF);
      PixelizrObjects.MakePictureTile(X, Y, X-GF.x, Y-GF.y, Oberon.CurCol, GF, T);
      NEW(G); Graphics.Open(G, "");
      NEW(F); GraphicFrames.Open(F, G); F.enabled := TRUE; F.handle := Handle;
      F.parent := GF; F.picture := T;
      PixelizrObjects.MakeBorderRectangle(Display.white, F);
      FOR X := 0 TO 31 DO
        FOR Y := 0 TO 31 DO
          i := PixelizrObjects.GetTileData(T, X, Y);
          s := SYSTEM.VAL(SET, i);
          IF X MOD 8 IN s THEN
            PixelizrObjects.MakeFill(Display.white, X * 16 + 16, Y * 16 + 16, F)
          END
        END
      END;
      Oberon.AllocateUserViewer(Oberon.Par.vwr.X, X, Y);
      V := MenuViewers.New(TextFrames.NewMenu("Pixelizr", Menu), F, TextFrames.menuH, X, Y)
    END
  END Open;

  PROCEDURE Apply*;
    VAR F: Frame;
  BEGIN
    F := Oberon.Par.vwr.dsc.next(Frame);
    PixelizrObjects.UpdatePictureTile(F.x + 25, F.y + 25, F.picture);
    GraphicFrames.DrawObj(F.parent, F.picture);
  END Apply;

BEGIN Texts.OpenWriter(W);
END Pixelizr.
