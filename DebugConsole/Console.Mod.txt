MODULE Console;

  IMPORT Kernel, Texts, Oberon;

  PROCEDURE LogString*(msg: ARRAY OF CHAR);
  BEGIN Kernel.ConsoleStr(msg); Kernel.ConsoleFlush();
  END LogString;

  PROCEDURE LogReader(VAR R: Texts.Reader; delim: CHAR);
    VAR ch: CHAR; continue: BOOLEAN;
  BEGIN continue := ~R.eot;
    WHILE continue DO
      Texts.Read(R, ch);
      continue := ~R.eot & (ch # delim);
      IF continue THEN Kernel.ConsoleCh(ch) END
    END;
    Kernel.ConsoleFlush();
  END LogReader;

  PROCEDURE LogText*(T: Texts.Text);
    VAR R: Texts.Reader;
  BEGIN
    Texts.OpenReader(R, T, 0);
    LogReader(R, 0X);
  END LogText;

  PROCEDURE LogBuf*(buf: Texts.Buffer);
    VAR T: Texts.Text;
  BEGIN
    NEW(T);
    Texts.Open(T, "");
    Texts.Append(T, buf);
    LogText(T)
  END LogBuf;

  (* command procedure; log argument surrounded by same delimiter, ^ reads selection *)
  PROCEDURE Log*;
    VAR R: Texts.Reader;
      ch: CHAR;
      T: Texts.Text;
      beg, end, time: INTEGER;
  BEGIN
    Texts.OpenReader(R, Oberon.Par.text, Oberon.Par.pos);
    Texts.Read(R, ch);
    WHILE ~R.eot & (ch <= " ") DO Texts.Read(R, ch) END;
    IF ch = "^" THEN
      Oberon.GetSelection(T, beg, end, time);
      IF time >= 0 THEN
        Texts.OpenReader(R, T, beg); Texts.Read(R, ch)
      ELSE
        ch := 0X;
      END
    END;
    IF ~R.eot & (ch # 0X) THEN LogReader(R, ch) END
  END Log;

  PROCEDURE Test*;
    VAR W: Texts.Writer;
  BEGIN
    Kernel.ConsoleHex(12345678H);
    Kernel.ConsoleLn();
    Kernel.ConsoleHex(0FEDCBA98H);
    Kernel.ConsoleHex(42);
    Kernel.ConsoleFlush();
    LogString("Hello!");
    Texts.OpenWriter(W);
    Texts.WriteString(W, "The answer is");
    Texts.WriteInt(W, 40+2, 3);
    Texts.WriteLn(W);
    Texts.WriteString(W, "And this is line #2");
    LogBuf(W.buf)
  END Test;

END Console.