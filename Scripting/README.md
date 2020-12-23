Scripting - Run multiple commands and react on their outcome

Description
-----------

Vanilla Oberon does not provide any measures to run multiple commands automatically, except
to put them into a `.Tool` file and let the user click them manually. There is a
[Batch execution facility](https://github.com/andreaspirklbauer/Oberon-batch-execution-facility)
available, that adds return codes as well as a way to run multiple commands, but this
is still linear, and will abort on the first error.

I also have a modification to add [exit codes](../CommandExitCodes/README.md) to commands,
which (unfortunately) is incompatible to Andreas' linked above. Building on this other
modification, this modification here introduces a simple scripting language that supports
branches (via `GoTo`) and variables. There is also an additional module available to add
a simple form of structured programming, if you do not like `GoTo`s.

A script consists of multiple commands, each of which is introduced by the `|>` marker.
The script ends with the `||` marker. A command can have an optional `Label`, in which case
the marker changes to `:Label|>`.

The Scripting language consists of four modules:


### `Script`

The `Script` module contains the main script execution engine, which is
responsible in running the script, handling `GoTo`s, pauses, and garbage collection.
It provides the `Script.Run` command (to run a script following the command),
`Script.RunFile` (to run a script elsewhere, in a file or in the selection), `Script.Collect`
(to run the garbage collector and continue the script afterwards), and `Script.GoTo`
to jump to a label while the script is running. When running a selection, it is sufficient
to mark the start of the script, it is not required to mark the whole script.

The module contains no conditional commands; those are found in `ScriptUtils` and `ScriptVars`.


### `ScriptUtils`

This module contains commands that are useful in the context of scripting, but which can
also be used standalone.


`ScriptUtils.ClearLog` clears the Log viewer, similar to `System.Clear` in the log viewer's
menu (which cannot be invoked from a script).

`ScriptUtils.WriteLog` writes a text (short string) to the log viewer. Before the text,
arguments can be given. A number argument writes that
many newlines, and `\` will omit the trailing newline. `*` will scroll the log viewer down
to have the newly written message as first line.

`ScriptUtils.WriteLogRaw` writes a raw text to the log viewer. The text can be longer
than 32 characters, and contain formatting or line breaks. It does not need to be delimited
by quotes; any non-whitespace character can be used.

`ScriptUtils.Fail` makes the script fail with the given exit code.

`ScriptUtils.ExpectFailure` will run the next command and **not** fail if the exit code matches.

`ScriptUtils.SortLines` sorts the lines in a file (if a file name is given) or a selection
(if `@` is given). In case the selection is only one character long, the rest of the text
until the end of the viewer is sorted. Arguments before the filename or `@` modify the sort
process: `\` inverses the search, `#` searches numerically, and a number sorts by that column.
In case a one-character string is given, the column is not by character index, but columns
are delimited by that character. For a two-character string, columns are delimited by the
first character followed by any number of the second character (i.e. padding). Both characters
can be the same (e.g. `"  "` for columns separated by any number of spaces).


### `ScriptVars`

This module contains commands that work with variables. Variables are Oberon text and can
therefore also contain formatting. There are no special commands to change the formatting,
but a variable can be shown in a Text viewer and selected there, thereby allowing to use
Edit commands to change the formatting.

The first argument of the commands is special: It can create new variables. All other
arguments can only refer to existing variables - it is an error if the variable does not
exist yet. On the contrary, the other arguments can also be numbers or strings, and will
automatically be converted to variables if needed. Positions can be given as normal (0 is
the start of the text and `Length` is the end), or as negative numbers indexed from the end
(-1 is the end, -2 is one character before it, etc.). There are no dedicated calculating
commands, but you can use the Calculator commands inside a script to do so.

Variables can be set by the `ScriptVars.Set`, `ScriptVars.SetChars` and `ScriptVars.SetRaw`
commands. They can also be loaded from or stored to a file `ScriptVars.Load`/`ScriptVars.Store`.

To show the content of a variable, `ScriptVars.ShowCopy` or `ScriptVars.ShowLive` can be used.
The latter will open a viewer that will change live when the variable is changed, and edits there
will affect the variable.

`ScriptVars.Insert` inserts one variable into another one at a certain position.
`ScriptVars.Cut` and `ScriptVars.Copy` can be used to move or copy part of a variable to
another one.

`ScriptVars.Length` stores the length of a variable in another variable, while `ScriptVars.CharCodeAt`
can be used to extract character codes from a variable.

`ScriptVars.Find` finds a text inside a variable, while `ScriptVars.Replace` can replace one or
more occurrences of one text by another one. Formatting is ignored when comparing texts.

To get texts into variables from the Oberon system, the `ScriptVars.CaptureLog`, `ScriptVars.CaptureError`
and `ScriptVars.CaptureViewer` (which can also close the viewer after capturing) commands can be used.

So far, variables have no impact on command execution. To change this, `ScriptVars.Compare` can compare
two variables (`=` for text comparison, `>`, `<`, `#` for numeric comparison) and run a command if the comparison
holds (`+`) or not (`-`). This command can also be a `Script.GoTo` command.

The two commands `ScriptVars.Expand` and `ScriptVars.ExpandLog` can be used to expand variables (between `%`)
in a command and run the expanded command. The second variant also prints the expanded command to the log window.
`%%` expands to a single percent sign, `%~` ends the command.


### `ScriptBlocks`

This module contains very primitive structured programming directives.

`ScriptBlocks.Begin` and `ScriptBlocks.End` mark a block of code (which may be nested).

`ScriptBlocks.Again` jumps back to the beginning of the enclosing block.

`ScriptBlocks.If` runs the next command, and if it fails, the commands after that command
are skipped (to the next `If` or to the end of the block). If the command succeeds, later `If`s
in the same block will fail (like `ELSIF`).

These commands are sufficient to mimic Oberon's control flow commands:

```
  IF condition1 THEN
    commands1
  ELSIF condition1 THEN
    commands2
  ELSE
    commands3
  END;

  |> ScriptBlocks.Begin
  |> ScriptBlocks.If condition1
  |> commands1
  |> ScriptBlocks.If condition2
  |> commands2
  |> ScriptBlocks.If ScriptUtils.Fail 0
  |> commands3
  |> ScriptBlocks.End`

  WHILE condition DO
    commands
  END;

  |> ScriptBlocks.Begin
  |> ScriptBlocks.If condition1
  |> commands
  |> ScriptBlocks.Again
  |> ScriptBlocks.End

  REPEAT
    commands
  UNTIL ~condition;

  |> ScriptBlocks.Begin
  |> commands
  |> ScriptBlocks.If condition
  |> ScriptBlocks.Again
  |> ScriptBlocks.End
```

That way, you can get a very limited environment for structured programming which may be easier
to use than `GoTo`s.


Installation
------------

- Install [CommandExitCodes](../CommandExitCodes/README.md), if not done already.

- Push the new modules.

- Compile the new modules:

      ORP.Compile ScriptUtils.Mod/s Script.Mod/s ~
      ORP.Compile ScriptVars.Mod/s ScriptBlocks.Mod/s ~

- You can find a list of commands in [Script.Tool](Script.Tool.txt).
