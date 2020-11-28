MODULE Clock;
  IMPORT SYSTEM, Display, Viewers, Texts, Oberon, MenuViewers, TextFrames;

  TYPE Frame = POINTER TO FrameDesc;
    Pos = RECORD x, y, dx, dy: INTEGER END ;
    FrameDesc = RECORD (Display.FrameDesc) myMenu: TextFrames.Frame; END ;
    UpdateMsg = RECORD (Display.FrameMsg) handled: BOOLEAN END ;

  VAR TT: Oberon.Task; W: Texts.Writer;

  PROCEDURE UpdateClock(F: Frame);
    VAR T: Texts.Text; buf: Texts.Buffer;
  BEGIN
    T := F.myMenu.text;
    NEW(buf); Texts.OpenBuf(buf); Texts.Delete(T, 35, T.len, buf);
    Texts.WriteClock(W, Oberon.Clock()); Texts.Append(T, W.buf);
    Texts.Delete(T, T.len-3, T.len, buf)
  END UpdateClock;

  PROCEDURE Handle(F: Display.Frame; VAR M: Display.FrameMsg);
    VAR F1: Frame;
  BEGIN
    CASE F OF Frame:
      CASE M OF
        Oberon.InputMsg:
          IF M(Oberon.InputMsg).id = Oberon.track THEN
            Oberon.DrawMouseArrow(M(Oberon.InputMsg).X, M(Oberon.InputMsg).Y)
          END
      | UpdateMsg: UpdateClock(F); M.handled := TRUE
      | MenuViewers.ModifyMsg:
        IF (M.Y # F.Y) OR (M.H # F.H) THEN
          F.Y := M.Y; F.H := M.H;
          Oberon.RemoveMarks(F.X, F.Y, F.W, F.H);
          Display.ReplConst(0, F.X+1, F.Y, F.W-1, F.H, 0);
        END
      END
    END
  END Handle;

  PROCEDURE Close*;
    VAR M: UpdateMsg;
  BEGIN
    IF Oberon.Par.vwr.dsc = Oberon.Par.frame THEN
      Viewers.Close(Oberon.Par.vwr);
      M.handled := FALSE;
      Viewers.Broadcast(M);
      IF ~M.handled THEN Oberon.Remove(TT) END
    END
  END Close;

  PROCEDURE UpdateClocks;
    VAR M: UpdateMsg;
  BEGIN Viewers.Broadcast(M)
  END UpdateClocks;

  PROCEDURE Show*;
    VAR T: Texts.Text;
      F: Frame;
      V: Viewers.Viewer;
      X, Y: INTEGER;
      beg, end, time: LONGINT;
  BEGIN NEW(F); Oberon.Install(TT); F.handle := Handle;
    Oberon.AllocateSystemViewer(Oberon.Par.vwr.X, X, Y);
    F.myMenu := TextFrames.NewMenu("Clock", "Clock.Close  |             ");
    V := MenuViewers.New(F.myMenu, F, TextFrames.menuH, X, TextFrames.menuH);
    UpdateClocks
  END Show;

BEGIN TT := Oberon.NewTask(UpdateClocks, 10000); Texts.OpenWriter(W)
END Clock.
