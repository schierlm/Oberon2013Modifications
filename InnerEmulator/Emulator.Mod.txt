MODULE Emulator;

  IMPORT SYSTEM, Files, Display, Texts, Oberon, EmulatorCore, EmulatorFrames;

  VAR
    S: Texts.Scanner;
    W: Texts.Writer;
    width, height, backColor, xorColor, outColor: INTEGER;
    useSerialPort: BOOLEAN;

  PROCEDURE GetArg(VAR S: Texts.Scanner);
    VAR T: Texts.Text; beg, end, time: LONGINT;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    IF (S.class = Texts.Char) & (S.c = "^") THEN
      Oberon.GetSelection(T, beg, end, time);
      IF time >= 0 THEN Texts.OpenScanner(S, T, beg); Texts.Scan(S) END
    END
  END GetArg;

  PROCEDURE ConfigureSize*;
    VAR S: Texts.Scanner;
  BEGIN GetArg(S);
    IF S.class = Texts.Int THEN width := S.i; Texts.Scan(S) END;
    IF S.class = Texts.Int THEN height := S.i END
  END ConfigureSize;

  PROCEDURE ConfigureColors*;
    VAR S: Texts.Scanner;
  BEGIN GetArg(S);
    IF S.class = Texts.Int THEN backColor := S.i; Texts.Scan(S) END;
    IF S.class = Texts.Int THEN xorColor := S.i; Texts.Scan(S) END;
    IF S.class = Texts.Int THEN outColor := S.i END
  END ConfigureColors;

  PROCEDURE ConfigureSerialOn*;
  BEGIN useSerialPort := TRUE
  END ConfigureSerialOn;

  PROCEDURE ConfigureSerialOff*;
  BEGIN useSerialPort := FALSE
  END ConfigureSerialOff;

  PROCEDURE Run*;
    VAR S: Texts.Scanner;
      E: EmulatorCore.Emulator;
      F: Files.File;
  BEGIN GetArg(S);
    IF S.class = Texts.Name THEN
      F := Files.Old(S.s);
      IF F # NIL THEN
        E := EmulatorCore.Init(F, EmulatorFrames.DisplayNotify, width, height, useSerialPort);
        IF E # NIL THEN
          EmulatorFrames.Open(E, backColor, xorColor, outColor, S.s);
          EmulatorCore.Reset(E, TRUE)
        END
      END
    END
  END Run;

  PROCEDURE GetEmulator(): EmulatorCore.Emulator;
    VAR F: Display.Frame; E: EmulatorCore.Emulator;
  BEGIN F := Oberon.Par.frame; E := NIL;
    IF (F # NIL) & (F.next IS EmulatorFrames.Frame) & (F = Oberon.Par.vwr.dsc) THEN
      E := F.next(EmulatorFrames.Frame).e;
    END
    RETURN E
  END GetEmulator;

  PROCEDURE Break*;
  BEGIN EmulatorCore.Reset(GetEmulator(), FALSE)
  END Break;

  PROCEDURE Reset*;
  BEGIN EmulatorCore.Reset(GetEmulator(), TRUE)
  END Reset;

  PROCEDURE Stop*;
  BEGIN EmulatorCore.Stop(GetEmulator())
  END Stop;

BEGIN Texts.OpenWriter(W); width := 1024; height := 768; useSerialPort := FALSE;
  backColor := 0; xorColor := 1; outColor := 0;
END Emulator.
