MODULE ImageTool;
  IMPORT SYSTEM, Kernel, Files, ImageKernel, ImageFileDir, ImageFiles, Texts, Oberon;

  PROCEDURE Init*;
  VAR S: Texts.Scanner;
    dp: ImageFileDir.DirPage;
    T: Texts.Text; beg, end, time: INTEGER;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    IF (S.class = Texts.Char) & (S.c = "^") THEN
      Oberon.GetSelection(T, beg, end, time);
      IF time >= 0 THEN Texts.OpenScanner(S, T, beg); Texts.Scan(S) END
    END;
    IF S.class = Texts.Name THEN
      ImageKernel.InitImage(S.s);
      dp.mark := ImageFileDir.DirMark;
      dp.p0 := 0;
      dp.m := 0;
      ImageKernel.PutSector(ImageFileDir.DirRootAdr, dp);
      ImageFiles.Init
    END
  END Init;

  PROCEDURE FreezeClock*;
  BEGIN ImageKernel.FreezeClock
  END FreezeClock;

  PROCEDURE AddFile(file: ARRAY OF CHAR);
    VAR f: Files.File;
      g: ImageFiles.File;
      Rf: Files.Rider;
      Rg: ImageFiles.Rider;
      ch: CHAR;
      i: INTEGER;
      newfile: ARRAY 32 OF CHAR;
  BEGIN f := Files.Old(file);
    ASSERT(f # NIL);
    newfile := file;
    i := 0;
    WHILE newfile[i] # 0X DO INC(i) END;
    IF (newfile[i-1] = "X") & (newfile[i-2] = ".") THEN newfile[i-2] := 0X END;
    g := ImageFiles.New(newfile);
    Files.Set(Rf, f, 0);
    ImageFiles.Set(Rg, g, 0);
    Files.Read(Rf, ch);
    WHILE ~Rf.eof DO ImageFiles.Write(Rg, ch); Files.Read(Rf, ch) END;
    ImageFiles.Register(g)
  END AddFile;

  PROCEDURE AddFiles*;
    VAR res: INTEGER; S: Texts.Scanner;
      T: Texts.Text; beg, end, time: INTEGER;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    IF (S.class = Texts.Char) & (S.c = "^") THEN
      Oberon.GetSelection(T, beg, end, time);
      IF time >= 0 THEN Texts.OpenScanner(S, T, beg); Texts.Scan(S) END
    END;
    WHILE S.class = Texts.Name DO
      AddFile(S.s);
      Texts.Scan(S)
    END
  END AddFiles;

  PROCEDURE Close*;
  BEGIN
    ImageKernel.Close;
  END Close;

  PROCEDURE CopyLinkArea*();
    VAR
      idx, sector, end: INTEGER;
      secbuf: ImageKernel.Sector;
  BEGIN end := 1024; idx := 0;
    sector := 2 * 29;
    WHILE (idx < end) DO
        Kernel.GetSector(sector, secbuf);
        ImageKernel.PutSector(sector, secbuf);
        IF sector = 2 * 29 THEN
           SYSTEM.GET(SYSTEM.ADR(secbuf)+16, end)
        END;
        INC(sector, 29);
        INC(idx, Kernel.SectorLength)
    END
  END CopyLinkArea;

  PROCEDURE CreateLinkArea*;
    VAR i, sector, beg, end, time: INTEGER; b: BYTE;
      F: Files.File; R: Files.Rider;
      S: Texts.Scanner; T: Texts.Text;
      buf: ImageKernel.Sector;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    IF (S.class = Texts.Char) & (S.c = "^") THEN
      Oberon.GetSelection(T, beg, end, time);
      IF time >= 0 THEN Texts.OpenScanner(S, T, beg); Texts.Scan(S) END
    END;
    IF S.class = Texts.Name THEN
      F := Files.Old(S.s);
      IF F # NIL THEN
        sector := 2 * 29; i := 0; Files.Set(R, F, 0); Files.ReadByte(R, b);
        WHILE ~R.eof DO buf[i] := b; INC(i);
          IF i = Kernel.SectorLength THEN ImageKernel.PutSector(sector, buf); INC(sector, 29); i := 0 END;
          Files.ReadByte(R, b)
        END;
        IF i > 0 THEN
          WHILE i < Kernel.SectorLength DO buf[i] := 0; INC(i) END;
          ImageKernel.PutSector(sector, buf)
        END
      END
    END
  END CreateLinkArea;

  PROCEDURE ExtractBootROM*();
    VAR
      iF: Files.File; iR: Files.Rider;
      oF: Files.File; oR: Files.Rider;
      S: Texts.Scanner; T: Texts.Text;
      i, beg, end, time: INTEGER; b: BYTE;
      name: ARRAY 32 OF CHAR;
  BEGIN
    Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    IF (S.class = Texts.Char) & (S.c = "^") THEN
      Oberon.GetSelection(T, beg, end, time);
      IF time >= 0 THEN Texts.OpenScanner(S, T, beg); Texts.Scan(S) END
    END;
    IF S.class = Texts.Name THEN
      iF := Files.Old(S.s);
      name := S.s; i := 0;
      WHILE (i < 32) & (name[i] # 0X) DO INC(i) END;
      ASSERT(i > 4);
      name[i-3] := "B"; name[i-2] := "i"; name[i-1] := "n";
      oF := Files.New(name);
      Files.Set(iR, iF, 23 + i);
      Files.Set(oR, oF, 0);
      FOR i := 0 TO 2047 DO
        Files.ReadByte(iR, b);
        Files.WriteByte(oR, b)
      END;
      Files.Close(iF);
      Files.Register(oF);
    END
  END ExtractBootROM;

END ImageTool.
