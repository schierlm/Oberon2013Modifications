RobustTrapViewer - Make sure TRAPs in system modules are seen

Description
-----------

When working inside System modules, sometimes the infrastructure that is required to
display TRAPs (Viewers, Texts) may trap itself. In that case, it is hard to even
recognize that a trap happened, and even harder to find out which one.

This module installs a trap handler which shows a box on the screen with trap details.
After a L+R mouse click, the trap is passed on to the original trap handler.


Installation
------------

- Push [`Trappy.Mod.txt`](Trappy.Mod.txt).

- Compile the new module:

    ORP.Compile Trappy.Mod/s ~

- Load and test the module using `Trappy.Test`.
