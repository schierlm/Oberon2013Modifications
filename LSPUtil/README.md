LSPUtil - Reformat or highlight Oberon source inside the system

Description
-----------

**NOTE**: Unlike other modifications, this modification is not standalone. It requires that
you applied the [LanguageServerProtocolHelper](../LanguageServerProtocolHelper/README.md)
modification before this modification.

This modification provides tools to run LSP's highlighter or formatter code from within
Oberon. The formatter uses a template file, which gives font and color for each syntax
element.

An example `VGATemplate` is provided that tries to mimic VS Code's default (dark) theme.
Optionally apply a changed color palette to mimic the colors even more closely (requires
[ColorSupport](../ColorSupport/README.md) and [ColorPalette](../ColorPalette/README.md)
modifications to be useful.


Installation
------------

- Apply [LanguageServerProtocolHelper](../ColorSupport/README.md), if not already applied.

- Push the new modules.

- Compile the new modules

      ORP.Compile LSPUtil.Mod/s ORHighlighter.Mod/s ORFormatter.Mod/s ~

- Restart the system.

- Use the commands in `LSPUtil.Tool`.
