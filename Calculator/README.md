Calculator - Simple prefix notation calculator

Description
-----------

Every OS has a calculator. Very useful if you need to do some quick calculations.
This calculator is very simple, it reads prefix notation from a buffer.
To calculate (2+3)*4 and output the result in decimal, you have to enter

    Calc.Dec * + 2 3 4

There are two calculators available. `Calc.Mod` calculates with integers,
and `RealCalc.Mod` calculates with floating point. This is historically, as
originally my JavaScript emulator did not support floating point and therefore
could not compile `RealCalc.Mod`.

Installation
------------

- Push the new modules and tools

- Compile the new modules:

      ORP.Compile Calc.Mod/s RealCalc.Mod/s ~

- Use the commands in [`Calc.Tool`](Calc.Tool.txt) and [`RealCalc.Tool`](RealCalc.Tool.txt).