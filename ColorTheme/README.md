ColorTheme - Configure which colors are used for UI elements

Description
-----------

**NOTE**: Unlike other modifications, this modification is not standalone. It requires that
you applied the `FixScrollCursorCorruption` fix (fix 6) from the [BugFixes](../BugFixes/README.md)
modification, before this modification.

When the [ColorSupport](../ColorSupport/README.md) modification is applied, the system supports
displays that can display 16 colors. Yet, everything on screen (except custom text/drawings)
is still black on white.

This modification identifies a few "color points" and provides an interface to assign colors
to them. Besides the default and inverted color theme, color themes are provided for 16-color
Oberon and VGA palettes, and a "Harlequin" theme that is very colorful.

The following colors can be configured (you can also configure only a subset of them, the
rest is filled with defaults as shown):

| Name                | Default value   | Used for                                    |
|:------------------- |:--------------- |:------------------------------------------- |
| FrameColor          | `Display.white` | Frame around viewers                        |
| BackgroundColor     | `Display.black` | Filler viewers                              |
| MenuBackgroundColor | FrameColor      | Menu viewer background                      |
| TextBackgroundColor | BackgroundColor | Text viewer background                      |
| ScrollMarkColor     | FrameColor      | Small mark that indicates scroll position   |
| ScrollBarColor      | FrameColor      | Separator line next to scroll bar           |
| CursorColor         | `Display.white` | Mouse pointer                               |
| ChangeMarkColor     | CursorColor     | Mark in top right corner indicating changes |
| SelectionColor      | CursorColor     | Highlight selected text                     |
| UnderlineColor      | CursorColor     | Underline clicked commands                  |

In addition, a flag can be configured that the text color should be mixed with the frame background color
before applying it in `Display.invert` mode. To set the flag, prepend the colors list with an asterisk.

Installation
------------

- Apply the prerequisite patch from the [BugFixes](../BugFixes/README.md) modification.

- Apply [`ColorTheme.patch`](ColorTheme.patch) to `Oberon.Mod`, `MenuViewers.Mod`,
  `TextFrames.Mod` and `System.Mod`.

- If you want to use the [UTF8CharsetLite](../UTF8CharsetLite) modification, apply
  [`UTF8CharsetLite.patch`](UTF8CharsetLite.patch) to `TextFramesU.Mod`.

- Push `ColorTheme.Tool`.

- Recompile `Oberon.Mod` and all dependencies (including the compiler):

      ORP.Compile Oberon.Mod/s ~
      ORP.Compile MenuViewers.Mod/s ~
      ORP.Compile TextFrames.Mod/s ~
      ORP.Compile System.Mod/s ~
      ORP.Compile Edit.Mod/s ~
      ORP.Compile ORS.Mod/s ORB.Mod/s ~
      ORP.Compile ORG.Mod/s ORP.Mod/s ~

- Restart the system.
