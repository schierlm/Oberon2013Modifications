MODULE Display;  (*autodetect color or b/w*)
  IMPORT SYSTEM, DisplayM, DisplayC;

  CONST black* = 0; white* = 15;  (*black = background*)
    replace* = 0; paint* = 1; invert* = 2;  (*modes*)

  TYPE Frame* = POINTER TO FrameDesc;
    FrameMsg* = RECORD END ;
    Handler* = PROCEDURE (F: Frame; VAR M: FrameMsg);
    FrameDesc* = RECORD next*, dsc*: Frame;
        X*, Y*, W*, H*: INTEGER;
        handle*: Handler
      END ;

  VAR Base*, Width*, Height*, Depth*, Span*: INTEGER;
    arrow*, star*, hook*, updown*, block*, cross*, grey*: INTEGER;
    (*a pattern is an array of bytes; the first is its width (< 32), the second its height, the rest the raster*)

    depth4Supported, depth1Supported: BOOLEAN;

  PROCEDURE Handle*(F: Frame; VAR M: FrameMsg);
  BEGIN
    IF (F # NIL) & (F.handle # NIL) THEN F.handle(F, M) END
  END Handle;

  PROCEDURE InitResolution*;
  BEGIN
    IF Depth = 4 THEN DisplayC.InitResolution
    ELSE DisplayM.InitResolution
    END
  END InitResolution;

  PROCEDURE SwitchToMono;
  BEGIN
    Base := DisplayM.Base;
    Width := DisplayM.Width;
    Height := DisplayM.Height;
    Span := DisplayM.Span;
    Depth := 1;
    arrow := DisplayM.arrow;
    star := DisplayM.star;
    hook := DisplayM.hook;
    updown := DisplayM.updown;
    block := DisplayM.block;
    cross := DisplayM.cross;
    grey := DisplayM.grey;
  END SwitchToMono;

  PROCEDURE SwitchTo4BitColor;
  BEGIN
    Base := DisplayC.Base;
    Width := DisplayC.Width;
    Height := DisplayC.Height;
    Span := DisplayC.Span;
    Depth := 4;
    arrow := DisplayC.arrow;
    star := DisplayC.star;
    hook := DisplayC.hook;
    updown := DisplayC.updown;
    block := DisplayC.block;
    cross := DisplayC.cross;
    grey := DisplayC.grey;
  END SwitchTo4BitColor;

  PROCEDURE SetSize*(w, h: INTEGER) : BOOLEAN;
    VAR result: BOOLEAN;
  BEGIN
    IF Depth = 4 THEN result := DisplayC.SetSize(w, h); SwitchTo4BitColor
    ELSE result := DisplayM.SetSize(w, h); SwitchToMono
    END
  RETURN result
  END SetSize;

  PROCEDURE SetDepth*(depth: INTEGER): BOOLEAN;
    VAR w, h: INTEGER; sizeset, result: BOOLEAN;
  BEGIN w := Width; h := Height; result := FALSE;
    IF (depth = 4) & depth4Supported  THEN SwitchTo4BitColor; result := TRUE
    ELSIF (depth = 1) & depth1Supported THEN SwitchToMono; result := TRUE
    END;
    IF result THEN
      sizeset := SetSize(w, h);
      IF ~sizeset THEN sizeset := SetSize(Width, Height) END
    END
  RETURN result
  END SetDepth;

  (* raster ops *)

  PROCEDURE Dot*(col, x, y, mode: INTEGER);
  BEGIN
    IF Depth = 4 THEN DisplayC.Dot(col, x, y, mode)
    ELSE DisplayM.Dot(col, x, y, mode)
    END
  END Dot;

  PROCEDURE ReplConst*(col, x, y, w, h, mode: INTEGER);
  BEGIN
    IF Depth = 4 THEN DisplayC.ReplConst(col, x, y, w, h, mode)
    ELSE DisplayM.ReplConst(col, x, y, w, h, mode)
    END
  END ReplConst;

  PROCEDURE CopyPattern*(col, patadr, x, y, mode: INTEGER);
  BEGIN
    IF Depth = 4 THEN DisplayC.CopyPattern(col, patadr, x, y, mode)
    ELSE DisplayM.CopyPattern(col, patadr, x, y, mode)
    END
  END CopyPattern;

  PROCEDURE CopyBlock*(sx, sy, w, h, dx, dy, mode: INTEGER);
  BEGIN
    IF Depth = 4 THEN DisplayC.CopyBlock(sx, sy, w, h, dx, dy, mode)
    ELSE DisplayM.CopyBlock(sx, sy, w, h, dx, dy, mode)
    END
  END CopyBlock;

  PROCEDURE ReplPattern*(col, patadr, x, y, w, h, mode: INTEGER);
  BEGIN
    IF Depth = 4 THEN DisplayC.ReplPattern(col, patadr, x, y, w, h, mode)
    ELSE DisplayM.ReplPattern(col, patadr, x, y, w, h, mode)
    END
  END ReplPattern;

  PROCEDURE GetPalette*(col: INTEGER; VAR val: INTEGER): BOOLEAN;
    VAR result: BOOLEAN;
  BEGIN
    IF Depth = 4 THEN result := DisplayC.GetPalette(col, val)
    ELSE result := DisplayM.GetPalette(col, val)
    END
  RETURN result
  END GetPalette;

  PROCEDURE SetPalette*(col, val: INTEGER);
  BEGIN
    IF Depth = 4 THEN DisplayC.SetPalette(col, val)
    ELSE DisplayM.SetPalette(col, val)
    END
  END SetPalette;

  PROCEDURE DetectDepths;
    VAR modes: INTEGER; tmp: BOOLEAN;
  BEGIN Depth := 0;
    SYSTEM.PUT(-4, 6D566964H); (* 'mVid' *)
    SYSTEM.GET(-4, modes);
    depth1Supported := modes > 0;
    SYSTEM.PUT(-4, 31366356H); (* '16cV' *)
    SYSTEM.GET(-4, modes);
    depth4Supported := modes > 0;
    IF ~depth4Supported THEN depth1Supported := TRUE END;
    IF depth1Supported THEN
      DisplayM.InitResolution;
      IF DisplayM.Span # 0 THEN SwitchToMono END
    END;
    IF depth4Supported THEN
      DisplayC.InitResolution;
      IF DisplayC.Span # 0 THEN SwitchTo4BitColor END
    END;
    IF Depth = 0 THEN (* unknown/unsupported mode active *)
      IF depth1Supported THEN SwitchToMono
      ELSIF depth4Supported THEN SwitchTo4BitColor
      END;
      IF Depth # 0 THEN tmp := SetSize(Width, Height) END
    END
  END DetectDepths;

BEGIN DetectDepths;
END Display.
