ColorPalette - Display and edit the color palette

Description
-----------

**NOTE**: Unlike other modifications, this modification is not standalone. It requires that
you applied the [ColorSupport](../ColorSupport/README.md) modification,
before this modification.

This modification provides simple tools to view the color palette and edit it (in 
case it is supported by hardware). It also includes a `Tool` file, which provides ways
to use two common 16 color palette configurations (VGA palette as well as Native Oberon
palette) even in case the board/emulator does not provide them.

Installation
------------

- Apply [ColorSupport](../ColorSupport/README.md), if not already applied.

- Push the new modules.

- Compile the new modules

      ORP.Compile ColorPalette.Mod/s PaletteEdit.Mod/s

- Restart the system.
