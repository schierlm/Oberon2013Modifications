MODULE TextsU;
  IMPORT Texts;

  PROCEDURE UnicodeWidth* (codepoint: INTEGER): INTEGER;
  VAR result: INTEGER;
  BEGIN
    IF codepoint < 80H THEN result := 1
    ELSIF codepoint < 800H THEN result := 2
    ELSIF codepoint < 10000H THEN result := 3
    ELSE result := 4 END;
  RETURN result
  END UnicodeWidth;

  PROCEDURE ReadUnicodeRest(VAR R: Texts.Reader; ch: CHAR; VAR codepoint: INTEGER);
  VAR i, more: INTEGER;
  BEGIN
    IF ORD(ch) < 80H THEN
      codepoint := ORD(ch); more := 0;
    ELSIF ORD(ch) < 0C0H THEN
      codepoint := 0FFFDH; more := 0;
    ELSIF ORD(ch) < 0E0H THEN
      codepoint := ORD(ch) MOD 20H; more := 1;
    ELSIF ORD(ch) < 0F0H THEN
      codepoint := ORD(ch) MOD 10H; more := 2;
    ELSIF ORD(ch) < 0F8H THEN
      codepoint := ORD(ch) MOD 08H; more := 3;
    ELSE
      codepoint := 0FFFDH; more := 0;
    END;
    FOR i := 1 TO more DO
      IF ~R.eot THEN Texts.Read(R, ch) END;
      codepoint := codepoint * 40H + (ORD(ch) MOD 40H)
    END;
    IF R.eot & (more > 0) THEN codepoint := 0FFFDH END;
  END ReadUnicodeRest;

  PROCEDURE ReadUnicode* (VAR R: Texts.Reader; VAR codepoint: INTEGER);
  VAR ch: CHAR;
  BEGIN Texts.Read(R, ch); ReadUnicodeRest(R, ch, codepoint)
  END ReadUnicode;

  PROCEDURE WriteUnicode* (VAR W: Texts.Writer; codepoint: INTEGER);
  BEGIN
    IF codepoint < 80H THEN
      Texts.Write(W, CHR(codepoint))
    ELSIF codepoint < 800H THEN
      Texts.Write(W, CHR(0C0H + (codepoint DIV 40H MOD 20H)));
      Texts.Write(W, CHR(080H + (codepoint MOD 40H)))
    ELSIF codepoint < 10000H THEN
      Texts.Write(W, CHR(0E0H + (codepoint DIV 1000H MOD 10H)));
      Texts.Write(W, CHR(080H + (codepoint DIV 40H MOD 40H)));
      Texts.Write(W, CHR(080H + (codepoint MOD 40H)))
    ELSE
      Texts.Write(W, CHR(0F0H + (codepoint DIV 40000H MOD 08H)));
      Texts.Write(W, CHR(080H + (codepoint DIV 1000H MOD 40H)));
      Texts.Write(W, CHR(080H + (codepoint DIV 40H MOD 40H)));
      Texts.Write(W, CHR(080H + (codepoint MOD 40H)))
    END
  END WriteUnicode;

END TextsU.
