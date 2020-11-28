Clock - Show a clock in the lower right corner

Description
-----------

When you have a working realtime clock, you may want to see the current time all the time.
This modification provides a simple clock in the lower right corner. It is implemented
as a menu viewer (with no content except the menu) that shows the clock inside the menu.
The clock is updated every 10 seconds until the last clock is closed.

Installation
------------

- Push [`Clock.Mod.txt`](Clock.Mod.txt).

- Compile the new module:

      ORP.Compile Clock.Mod/s ~

- Show the clock:

      Clock.Show
