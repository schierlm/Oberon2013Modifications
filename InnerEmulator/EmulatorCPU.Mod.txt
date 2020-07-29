MODULE EmulatorCPU;

  IMPORT SYSTEM;

  CONST DisplayStart* = 0E7F00H; DisplayEnd* = 0FFF80H;
    RomStart* = 0FE000H; IoStart* = 0FFFC0H; MemSize* = 100000H;

  TYPE State* = POINTER TO StateDesc;
       Mem* = POINTER TO MemDesc;
    IOHandler* = PROCEDURE(s: State; write: BOOLEAN; address: INTEGER; VAR val: INTEGER);

    MemDesc* = RECORD
      ram*: ARRAY DisplayStart OF BYTE;
      vid*: ARRAY DisplayEnd - DisplayStart OF BYTE;
    END;

    StateDesc* = RECORD
      mem*: Mem;
      regs*: ARRAY 16 OF INTEGER;
      regPC*, regH*: INTEGER;
      flagZ*, flagN*, flagC*, flagV*, needUpdate: BOOLEAN;
      minX, maxX, minY, maxY, width*, height*: INTEGER;
      handleIO: IOHandler;
    END;

  VAR rom: ARRAY 83 OF INTEGER;

  PROCEDURE Init*(s: State; width, height: INTEGER; handleIO: IOHandler);
  BEGIN NEW(s.mem);
    s.width := width; s.height := height;
    s.minX := width; s.minY := height; s.maxX := -1; s.maxY := -1;
    s.handleIO := handleIO;
  END Init;

  PROCEDURE NotifyDisplayNeeded*(s: State; VAR minX, maxX, minY, maxY: INTEGER) : BOOLEAN;
    VAR result: BOOLEAN;
  BEGIN result := FALSE;
    IF s.needUpdate THEN
      result := TRUE; s.needUpdate := FALSE;
      minX := s.minX; s.minX := s.width;
      maxX := s.maxX; s.maxX := -1;
      minY := s.minY; s.minY := s.height;
      maxY := s.maxY; s.maxY := -1
    END
  RETURN result
  END NotifyDisplayNeeded;

  PROCEDURE PutRegister*(s: State; idx, value: INTEGER);
  BEGIN
    s.flagZ := (value = 0);
    s.flagN := (value < 0);
    s.regs[idx] := value
  END PutRegister;

  PROCEDURE PutSpecialRegisters*(s: State; regPC, regH: INTEGER; flagZ, flagN, flagC, flagV: BOOLEAN);
  BEGIN
    s.regPC := regPC;
    s.regH := regH;
    s.flagZ := flagZ;
    s.flagN := flagN;
    s.flagC := flagC;
    s.flagV := flagV
  END PutSpecialRegisters;

  PROCEDURE ReadWord(s: State; address: INTEGER; mapROM: BOOLEAN; VAR val: INTEGER);
  BEGIN
    IF mapROM & (address >= RomStart) & (address < RomStart + LEN(rom) * 4) THEN
      val := rom[(address - RomStart) DIV 4]
    ELSIF address >= IoStart THEN
      s.handleIO(s, FALSE, address, val)
    ELSIF address < DisplayEnd THEN
      SYSTEM.GET(SYSTEM.ADR(s.mem.ram) + address, val)
    ELSE
      val := 0
    END
  END ReadWord;

  PROCEDURE UpdateDisplay(s: State; offset: INTEGER);
    VAR x, y: INTEGER;
  BEGIN
    x := offset MOD 32 * 32;
    y := offset DIV 32;
    IF (x < s.width) & (y < s.height) THEN
      IF x < s.minX THEN s.minX := x END;
      IF x + 31 > s.maxX THEN s.maxX := x + 31 END;
      IF y < s.minY THEN s.minY := y END;
      IF y > s.maxY THEN s.maxY := y END;
      s.needUpdate := TRUE
    END
  END UpdateDisplay;

  PROCEDURE WriteWord*(s: State; address, value: INTEGER);
  BEGIN
    IF address >= IoStart THEN
      s.handleIO(s, TRUE, address, value);
    ELSIF address < DisplayEnd THEN
      SYSTEM.PUT(SYSTEM.ADR(s.mem.ram) + address, value);
      IF address >= DisplayStart THEN
        UpdateDisplay(s, (address - DisplayStart) DIV 4)
      END
    END
  END WriteWord;

  PROCEDURE Reset*(s: State; cold: BOOLEAN);
  BEGIN
    s.regPC := RomStart DIV 4;
    IF cold THEN PutRegister(s, 15, 0) END
  END Reset;

  PROCEDURE SetDiff(a, b:SET): SET;
  BEGIN
  RETURN a-b
  END SetDiff;

  PROCEDURE Step*(s: State);
    CONST pbit = 31; qbit = 30; ubit = 29; vbit = 28;
      (* branch opcodes *)
      MI = 0; EQ = 1; CS = 2; VS = 3; LS = 4; LT = 5; LE = 6; TT = 7;
      (* normal opcodes *)
      Mov = 0; Lsl = 1; Asr = 2; Ror = 3;  And = 4;  Ann = 5; Ior = 6; Xor = 7;
      Add = 8; Sub = 9; Mul = 10; Div = 11; Fad = 12; Fsb = 13; Fml = 14; Fdv = 15;

    VAR t: BOOLEAN; irSet: SET;
      pc, ir, a, b, op, im, c, aVal, bVal, cVal, off, addr: INTEGER;
  BEGIN
    pc := s.regPC;
    ReadWord(s, pc * 4, TRUE, ir);
    irSet := SYSTEM.VAL(SET, ir);
    INC(s.regPC);
    IF ~(pbit IN irSet) THEN
      a := ir DIV 1000000H MOD 10H;
      b := ir DIV 100000H MOD 10H;
      op := ir DIV 10000H MOD 10H;
      im := ir MOD 10000H;
      c := ir MOD 10H;
      bVal := s.regs[b];
      IF ~(qbit IN irSet) THEN
        cVal := s.regs[c]
      ELSIF ~(vbit IN irSet) THEN
        cVal := im;
      ELSE
        cVal := 0FFFF0000H + im
      END;
      IF op = Mov THEN
        IF ~(ubit IN irSet) THEN
          aVal := cVal
        ELSIF qbit IN irSet THEN
          aVal := cVal * 10000H
        ELSIF vbit IN irSet THEN
          aVal := 0D0H;
          IF s.flagN THEN aVal := aVal + 80000000H END;
          IF s.flagZ THEN aVal := aVal + 40000000H END;
          IF s.flagC THEN aVal := aVal + 20000000H END;
          IF s.flagV THEN aVal := aVal + 10000000H END;
        ELSE
          aVal := s.regH;
        END
      ELSIF op = Lsl THEN
        aVal := LSL(bVal, cVal)
      ELSIF op = Asr THEN
        aVal := ASR(bVal, cVal)
      ELSIF op = Ror THEN
        aVal := ROR(bVal, cVal)
      ELSIF op = And THEN
        aVal := SYSTEM.VAL(INTEGER, SYSTEM.VAL(SET, bVal) * SYSTEM.VAL(SET, cVal))
      ELSIF op = Ann THEN
        aVal := SYSTEM.VAL(INTEGER, SetDiff(SYSTEM.VAL(SET, bVal), SYSTEM.VAL(SET, cVal)))
      ELSIF op = Ior THEN
        aVal := SYSTEM.VAL(INTEGER, SYSTEM.VAL(SET, bVal) + SYSTEM.VAL(SET, cVal))
      ELSIF op = Xor THEN
        aVal := SYSTEM.VAL(INTEGER, SYSTEM.VAL(SET, bVal) / SYSTEM.VAL(SET, cVal))
      ELSIF op = Add THEN
        aVal := bVal + cVal;
        IF (ubit IN irSet) & s.flagC THEN INC(aVal) END;
        s.flagC := (aVal - 80000000H) < (bVal - 80000000H);
        s.flagV := (ASR(bVal,31) = ASR(cVal,31)) & (ASR(aVal,31) # ASR(bVal,31));
      ELSIF op = Sub THEN
        aVal := bVal - cVal;
        IF (ubit IN irSet) & s.flagC THEN DEC(aVal) END;
        s.flagC := (aVal - 80000000H) > (bVal - 80000000H);
        s.flagV := (ASR(bVal,31) # ASR(cVal,31)) & (ASR(aVal,31) # ASR(bVal,31));
      ELSIF op = Mul THEN
        (* this is lazy and exploits the fact that the host's multiply function works the same *)
        IF ~(ubit IN irSet) THEN
          aVal := bVal * cVal
        ELSE
          aVal := UML(bVal, cVal)
        END;
        s.regH := SYSTEM.H(0)
      ELSIF op = Div THEN
        (* this is lazy and exploits the fact that the host's divide function works the same *)
        IF ~(ubit IN irSet) THEN
          aVal := bVal DIV cVal;
        ELSE (* never generated by ORG; would be unsigned division *)
          ASSERT(FALSE); aVal := 0
        END;
        s.regH := SYSTEM.H(0)
      ELSIF (op = Fad) OR (op = Fsb) THEN
        IF op = Fsb THEN
          cVal := cVal - 80000000H
        END;
        IF (~(ubit IN irSet)) & (~(vbit IN irSet)) THEN
          aVal := SYSTEM.VAL(INTEGER, SYSTEM.VAL(REAL, bVal) + SYSTEM.VAL(REAL, cVal))
        ELSIF (ubit IN irSet) & (~(vbit IN irSet)) & (cVal = 4B000000H) THEN
          aVal := SYSTEM.VAL(INTEGER, FLT(bVal))
        ELSIF (~(ubit IN irSet)) & (vbit IN irSet) & (cVal = 4B000000H) THEN
          aVal := FLOOR(SYSTEM.VAL(REAL, bVal))
        ELSE (* never generated by ORG *)
          ASSERT(FALSE); aVal := 0
        END
      ELSIF op = Fml THEN
        aVal := SYSTEM.VAL(INTEGER, SYSTEM.VAL(REAL, bVal) * SYSTEM.VAL(REAL, cVal))
      ELSIF op = Fdv THEN
        aVal := SYSTEM.VAL(INTEGER, SYSTEM.VAL(REAL, bVal) / SYSTEM.VAL(REAL, cVal))
      END;
      PutRegister(s, a, aVal);
    ELSIF ~(qbit IN irSet) THEN
      a := ir DIV 1000000H MOD 10H;
      b := ir DIV 100000H MOD 10H;
      off := ir MOD 100000H;
      IF off >= 80000H THEN DEC(off, 100000H) END;
      addr := (s.regs[b] + off) MOD MemSize;
      IF ~(ubit IN irSet) THEN
        ReadWord(s, addr DIV 4 * 4, FALSE, aVal);
        IF vbit IN irSet THEN
          aVal := ASR(aVal, addr MOD 4 * 8) MOD 100H
        END;
        PutRegister(s, a, aVal)
      ELSE
        IF ~(vbit IN irSet) THEN
          WriteWord(s, addr, s.regs[a]);
        ELSIF addr < IoStart THEN
          bVal := addr MOD 4 * 8;
          ReadWord(s, addr DIV 4 * 4, FALSE, aVal);
          aVal := SYSTEM.VAL(INTEGER, SetDiff(SYSTEM.VAL(SET, aVal), {bVal .. bVal+7})) + LSL(s.regs[a] MOD 100H, bVal);
          WriteWord(s, addr DIV 4 * 4, aVal)
        ELSE
          WriteWord(s, addr, s.regs[a] MOD 100H)
        END
      END
    ELSE
      op := ir DIV 1000000H MOD 8;
      IF op = MI THEN t := s.flagN
      ELSIF op = EQ THEN t := s.flagZ
      ELSIF op = CS THEN t := s.flagC
      ELSIF op = VS THEN t := s.flagV
      ELSIF op = LS THEN t := s.flagC OR s.flagZ
      ELSIF op = LT THEN t := ORD(s.flagN) # ORD(s.flagV)
      ELSIF op = LE THEN t := (ORD(s.flagN) # ORD(s.flagV)) OR s.flagZ
      ELSIF op = TT THEN t := TRUE
      END;
      IF ir DIV 8000000H MOD 2 # 0 THEN t := ~t END;
      IF t THEN
        IF vbit IN irSet THEN
          PutRegister(s, 15, s.regPC * 4)
        END;
        IF ~(ubit IN irSet) THEN
          s.regPC := (s.regs[ir MOD 10H] MOD MemSize) DIV 4;
        ELSE
          s.regPC := (s.regPC + ir MOD 1000000H) MOD (MemSize DIV 4);
        END
      END
    END
  END Step;

  PROCEDURE InitROM;
  BEGIN
    rom[0] := 0E700002BH;  rom[1] := 000000000H;  rom[2] := 000000000H;  rom[3] := 000000000H;
    rom[4] := 000000000H;  rom[5] := 000000000H;  rom[6] := 000000000H;  rom[7] := 000000000H;
    rom[8] := 04EE90010H;  rom[9] := 0AFE00000H;  rom[10] := 040000000H; rom[11] := 0A0E00004H;
    rom[12] := 0A0E00008H; rom[13] := 0A0E0000CH; rom[14] := 040000002H; rom[15] := 0A0E00004H;
    rom[16] := 040000000H; rom[17] := 0A0E00008H; rom[18] := 05000FFE4H; rom[19] := 081E00008H;
    rom[20] := 0A1000000H; rom[21] := 060008000H; rom[22] := 081E00004H; rom[23] := 000080001H;
    rom[24] := 05100FFE4H; rom[25] := 0A0100000H; rom[26] := 080E00008H; rom[27] := 0E9000003H;
    rom[28] := 040000010H; rom[29] := 080000000H; rom[30] := 0A0E0000CH; rom[31] := 080E00004H;
    rom[32] := 040080001H; rom[33] := 0A0E00004H; rom[34] := 080E00008H; rom[35] := 040080400H;
    rom[36] := 0A0E00008H; rom[37] := 080E00008H; rom[38] := 081E0000CH; rom[39] := 000090001H;
    rom[40] := 0E5FFFFE9H; rom[41] := 08FE00000H; rom[42] := 04EE80010H; rom[43] := 0C700000FH;
    rom[44] := 00B00000EH; rom[45] := 05E00FFC0H; rom[46] := 060000008H; rom[47] := 00E000000H;
    rom[48] := 04C000020H; rom[49] := 00000000FH; rom[50] := 040090000H; rom[51] := 0E9000006H;
    rom[52] := 040000082H; rom[53] := 05100FFC4H; rom[54] := 0A0100000H; rom[55] := 0DF025C0CH;
    rom[56] := 0F7FFFFCFH; rom[57] := 0E7000005H; rom[58] := 00000000BH; rom[59] := 040090000H;
    rom[60] := 0E1000002H; rom[61] := 00000000BH; rom[62] := 00E000000H; rom[63] := 04000000CH;
    rom[64] := 06100000EH; rom[65] := 041167EF0H; rom[66] := 0A1000000H; rom[67] := 040000018H;
    rom[68] := 061000008H; rom[69] := 0A1000000H; rom[70] := 040000084H; rom[71] := 05100FFC4H;
    rom[72] := 0A0100000H; rom[73] := 040000000H; rom[74] := 0C7000000H; rom[75] := 000000100H;
    rom[76] := 00000B000H; rom[77] := 0FFFFFF00H; rom[78] := 0000000FFH; rom[79] := 000000000H;
    rom[80] := 000000000H; rom[81] := 00000B000H; rom[82] := 000004F00H
  END InitROM;

BEGIN InitROM
END EmulatorCPU.
