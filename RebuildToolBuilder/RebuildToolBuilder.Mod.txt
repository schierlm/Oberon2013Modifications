MODULE RebuildToolBuilder;
  IMPORT FileDir, Files, Modules, Viewers, Texts, Oberon, MenuViewers, TextFrames;

  CONST StandardMenu = "System.Close System.Copy System.Grow Edit.Search Edit.Store";

  TYPE
    ModInfo = POINTER TO ModInfoDesc;
    ModInfoDesc = RECORD
      name: Modules.ModuleName;
      next, firstDepends: ModInfo;
      rscDate, modDate: INTEGER;
      changeFlag: CHAR;
    END;

  VAR W: Texts.Writer;
    root: ModInfo;

  PROCEDURE GetModuleName(filename: FileDir.FileName; VAR mname, ext: Modules.ModuleName);
    VAR i, j: INTEGER;
  BEGIN i := 0; j := 0;
    WHILE (filename[i] # 0X) & (filename[i] # ".") DO mname[i] := filename[i]; INC(i) END;
    mname[i] := 0X;
    WHILE filename[i] # 0X DO ext[j] := filename[i]; INC(i); INC(j) END;
    ext[j] := 0X
  END GetModuleName;

  PROCEDURE List(fname: FileDir.FileName; adr: LONGINT; VAR cont: BOOLEAN);
    VAR i: INTEGER; b: BYTE;
      mname, ext: Modules.ModuleName;
      F: Files.File;
      R: Files.Rider;
      mi, dmi: ModInfo;
  BEGIN
    GetModuleName(fname, mname, ext);
    IF (ext = ".rsc") OR (ext = ".Mod") THEN
      mi := root;
      WHILE (mi # NIL) & (mi.name # mname) DO mi := mi.next END;
      IF mi = NIL THEN
        NEW(mi);
        mi.name := mname;
        mi.rscDate := -1;
        mi.modDate := -1;
        mi.next := root;
        root := mi
      END;
      F := Files.Old(fname);
      IF ext = ".rsc" THEN
        Files.Set(R, F, 0); Files.ReadString(R, mname);
        Files.ReadInt(R, i); Files.ReadByte(R, b);
        Files.ReadInt(R, i); Files.ReadString(R, mname);
        WHILE mname[0] # 0X DO
          NEW(dmi); dmi.name := mname;
          dmi.next := mi.firstDepends; mi.firstDepends := dmi;
          Files.ReadInt(R, i); Files.ReadString(R, mname)
        END;
        mi.rscDate := Files.Date(F)
      ELSE
        mi.modDate := Files.Date(F)
      END;
      Files.Close(F);
    END;
  END List;

  PROCEDURE Build*;
    VAR x, y: INTEGER;
      T: Texts.Text;
      S: Texts.Scanner;
      V: Viewers.Viewer;
      mi, mi2, mi3, done: ModInfo;
      opts: ARRAY 9 OF CHAR;
      missing: BOOLEAN;
  BEGIN
    Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S); x := 0;
    WHILE (S.class = Texts.Char) & (S.c = "/") DO
      opts[x] := S.c; Texts.Scan(S); INC(x);
      IF S.class = Texts.Name THEN opts[x] := S.s[0]; INC(x); Texts.Scan(S) END
    END;
    opts[x] := 0X;
    root := NIL; done := NIL; missing := FALSE;
    Oberon.AllocateUserViewer(Oberon.Par.vwr.X, x, y); T := TextFrames.Text("");
    V := MenuViewers.New(
      TextFrames.NewMenu("Rebuild.Tool", StandardMenu),
      TextFrames.NewText(T, 0), TextFrames.menuH, x, y);
    FileDir.Enumerate("", List);
    mi := root;
    WHILE mi # NIL DO
      IF mi.modDate = -1 THEN
        Texts.WriteString(W, "  missing ");
        Texts.WriteString(W, mi.name);
        Texts.WriteString(W, ".Mod");
        Texts.WriteLn(W);
        missing := TRUE;
      ELSIF mi.rscDate = -1 THEN
        Texts.WriteString(W, "  missing ");
        Texts.WriteString(W, mi.name);
        Texts.WriteString(W, ".rsc: ORP.Compile ");
        Texts.WriteString(W, mi.name);
        Texts.WriteString(W, ".Mod/s");
        Texts.WriteString(W, opts);
        Texts.WriteString(W, " ~");
        Texts.WriteLn(W);
        missing := TRUE;
      ELSIF mi.rscDate = mi.modDate THEN
        mi.changeFlag := "?";
      ELSIF mi.rscDate < mi.modDate THEN
        mi.changeFlag := "!";
      ELSE
        mi.changeFlag := "-";
      END;
      mi := mi.next;
    END;
    IF ~missing & (root # NIL) THEN
      mi := root; x := 0;
      WHILE mi.next # NIL DO mi := mi.next END;
      mi.next := root; (* build loop *)
      WHILE mi.next # NIL DO
        missing := FALSE;
        mi2 := mi.next.firstDepends;
        WHILE (~missing) & (mi2 # NIL) DO
          mi3 := done;
          WHILE (mi3 # NIL) & (mi3.name # mi2.name) DO mi3 := mi3.next END;
          IF mi3 = NIL THEN missing := TRUE
          ELSE mi2 := mi2.next;
            IF (mi.next.changeFlag # "!") & ((mi3.changeFlag # "-") OR (mi3.modDate >= mi.next.rscDate)) THEN mi.next.changeFlag := "*" END
          END
        END;
        IF ~missing THEN
          Texts.WriteString(W, "ORP.Compile ");
          Texts.WriteString(W, mi.next.name);
          Texts.WriteString(W, ".Mod/s");
          Texts.WriteString(W, opts);
          Texts.WriteString(W, " ~ [");
          Texts.Write(W, mi.next.changeFlag);
          Texts.Write(W, "]");
          Texts.WriteLn(W);
        ELSIF x > 1000 THEN
          missing := FALSE;
          Texts.WriteString(W, "  unsatisfiable imports for ");
          Texts.WriteString(W, mi.next.name);
          Texts.WriteString(W, ".Mod: ");
          mi2 := mi.next.firstDepends;
          WHILE mi2 # NIL DO
            Texts.WriteString(W, mi2.name);
            Texts.Write(W, " ");
            mi2 := mi2.next
          END;
          Texts.WriteLn(W);
        END;
        IF ~missing THEN
          IF mi.next = mi THEN (* last item done *)
            mi.next := NIL; done := NIL;
          ELSE
            x := 0;
            mi2 := mi.next;
            mi.next := mi.next.next;
            mi2.next := done;
            done := mi2
          END
        ELSE
          INC(x); mi := mi.next
        END
      END
    END;
    root := NIL;
    Texts.Append(T, W.buf)
  END Build;

BEGIN Texts.OpenWriter(W);
END RebuildToolBuilder.
