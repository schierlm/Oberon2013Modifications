Script.Run
|> Script.Collect
|> ScriptUtils.ExpectFailure 44 ScriptUtils.Fail 44
|> System.Watch
||

Script.GoTo SomeLabel
Script.RunFile @ ~
Script.RunFile Example.Script ~
Script.RunFile Example.Script StartLabel ~

ScriptUtils.ClearLog
ScriptUtils.WriteLog "Hello"
ScriptUtils.WriteLog 3 "After three newlines"
ScriptUtils.WriteLog \ "No newline at end"
ScriptUtils.WriteLog * "Scrolling to new log message"

ScriptUtils.WriteLogRaw "This log message can be really long and also contain formatting
  or even line breaks"
ScriptUtils.WriteLogRaw /You can use "different" separator characters, any non-space will work/

ScriptUtils.SortLines Example.Text
ScriptUtils.SortLines @
ScriptUtils.SortLines \ 5 @
ScriptUtils.SortLines \ # "  " 4 @ (* files/modules *)

ScriptVars.Set Greeting "Hello, World!"
ScriptVars.ShowCopy ^
ScriptVars.ShowLive Greeting
ScriptVars.ShowCopy Greeting 7 -2 (* mark "World" *)

ScriptVars.SetChars Newline 13 ~
ScriptVars.SetRaw LongGreeting /I want to say hello to everybody in the whole world!/
ScriptVars.Load Sample "System.Tool"
ScriptVars.Store LongGreeting "Greeting.Text"
ScriptVars.Insert Greeting " again" 5
ScriptVars.Cut Trash Greeting 5 11
ScriptVars.Copy Place Greeting 7 -2
ScriptVars.Length Len Greeting
ScriptVars.CharCodeAt ExclamationMark Greeting -2
ScriptVars.Find Position Greeting 0 "orl"
ScriptVars.Replace Greeting 0 "o" 99 "u"
ScriptVars.CaptureLog Greeting ScriptUtils.WriteLog "Indirect Hello" ~
ScriptVars.CaptureError Answer ScriptUtils.Fail 42
    System.Directory *.Bak
ScriptVars.CaptureViewer BakFiles - "System.Directory"
ScriptVars.Compare Len > 7 + ScriptUtils.WriteLog "Greeting is longer than 7"
ScriptVars.Expand ScriptUtils.WriteLogRaw 'The greeting is for %Place% and %Len% long %Newline%' %~
ScriptVars.ExpandLog ScriptUtils.WriteLog "%Greeting% (100%%)" %~

Script.Run
 |> System.Directory *.Bak ~
 |> ScriptVars.CaptureViewer FileList - "System.Directory" ~
 |> ScriptVars.Expand System.DeleteFiles %FileList% ~ %~
 ||

Script.Run
 |> RebuildToolBuilder.Build ~
 |> ScriptVars.CaptureViewer Cmds - "Rebuild.Tool" ~
 |> ScriptVars.SetChars NL 13 ~
 :Loop|> ScriptVars.Find Pos Cmds 0 NL ~
 |> ScriptVars.Compare Pos # 0 - Script.GoTo Done ~
 |> ScriptVars.Cut Cmd Cmds 0 Pos ~
 |> ScriptVars.Cut Trash Cmds 0 1 ~
 |> ScriptVars.Expand %Cmd% %~
 |> Script.Collect
 |> Script.GoTo Loop ~
 :Done|> ScriptUtils.WriteLog "Everything recompiled!" ~
 ||

Script.Run
 |> RebuildToolBuilder.Build ~
 |> ScriptVars.CaptureViewer Cmds - "Rebuild.Tool" ~
 |> ScriptVars.SetChars NL 13 ~
 |> ScriptBlocks.Begin
 |> ScriptVars.Find Pos Cmds 0 NL ~
 |> ScriptBlocks.If ScriptVars.Compare Pos # 0 - ScriptUtils.Fail 1 ~
 |> ScriptVars.Cut Cmd Cmds 0 Pos ~
 |> ScriptVars.Cut Trash Cmds 0 1 ~
 |> ScriptVars.Expand %Cmd% %~
 |> Script.Collect
 |> ScriptBlocks.Again
 |> ScriptBlocks.End
 |> ScriptUtils.WriteLog "Everything recompiled!" ~
 ||



