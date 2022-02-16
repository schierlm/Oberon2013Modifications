MODULE SeamlessResize;
  IMPORT SYSTEM, Kernel, Display, Oberon;

  VAR
    t: Oberon.Task;
    installed: BOOLEAN;
    hwAddr: INTEGER;

  PROCEDURE Run*;
  BEGIN
    IF ~installed & (hwAddr # 0) THEN
      Oberon.Install(t);
      installed := TRUE
    END
  END Run;

  PROCEDURE Stop*;
  BEGIN
    IF installed THEN
      Oberon.Remove(t);
      installed := FALSE
    END
  END Stop;

  PROCEDURE Check;
    VAR w, h, val: INTEGER;
  BEGIN val := 40000000H;
    IF Display.Depth = 4 THEN val := 0C0000000H END;
    SYSTEM.PUT(hwAddr, val);
    SYSTEM.GET(hwAddr, val);
    w := val DIV 8000H MOD 8000H;
    h := val MOD 8000H;
    IF (w # Display.Width) OR (h # Display.Height) THEN
      IF Display.SetSize(w, h) THEN
        Oberon.UpdateScreenSize();
      END
    END
  END Check;

  PROCEDURE Init;
    VAR hwid, val: INTEGER;
  BEGIN
    hwid := Kernel.ToHardwareID("mDyn");
    IF Display.Depth = 4 THEN hwid := Kernel.ToHardwareID("16cD") END;
    SYSTEM.PUT(Kernel.hwEnumerator, hwid);
    SYSTEM.GET(Kernel.hwEnumerator, hwAddr);
    SYSTEM.GET(Kernel.hwEnumerator, val);
    SYSTEM.GET(Kernel.hwEnumerator, val);
    SYSTEM.GET(Kernel.hwEnumerator, val);
    SYSTEM.GET(Kernel.hwEnumerator, val);
    SYSTEM.GET(Kernel.hwEnumerator, val);
    SYSTEM.GET(Kernel.hwEnumerator, val);
    SYSTEM.GET(Kernel.hwEnumerator, val);
    IF Display.Depth = 4 THEN SYSTEM.GET(Kernel.hwEnumerator, val) END;
    IF val # 1 THEN hwAddr := 0 END;
  END Init;

BEGIN
  installed := FALSE;
  IF (Display.Depth = 1) OR (Display.Depth = 4) THEN Init ELSE hwAddr := 0 END;
  t := Oberon.NewTask(Check, 5000);
END SeamlessResize.
