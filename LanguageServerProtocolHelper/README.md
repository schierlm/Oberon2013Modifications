LanguageServerProtocolHelper - Backend service for an Oberon LSP Server

Description
-----------

VS Code introduced the concept of a "Language server", a server written in the target
language that uses the original compiler for providing diagnostics and navigation
features. However, the protocol (based on JSON-RPC) is quite fat and nothing you
want to implement in Oberon.

Therefore, a two-component solution has been chosen. A classic language server is
implemented in Java, talks JSON-RPC to the client (VS Code), and a custom binary
protocol is used between this language server and a LSP helper written in Oberon.

This modification implements the LSP helper for Project Oberon 2013 (and Extended
Oberon and Oberon Retro Compiler).

See the [LSP Helper protocol specification](protocol.md) for more details.

Installation
------------

- Push [`LSPhConstants.Mod.txt`](LSPhConstants.Mod.txt) and 
  [`LSPhServer.Mod.txt`](LSPhServer.Mod.txt).

- Create a copy of `ORS.Mod`, `ORB.Mod`, `ORG.Mod`, and `ORP.Mod`; name these copies
  `LSPhORS.Mod` etc.
  
- Apply [`LSPHelper.patch`](LSPHelper.patch) to the newly created files.

- Apply [`RS232.patch`](../KernelDebugger/RS232.patch) from the **KernelDebugger** 
  modification to `RS232.Mod` (if not already applied).

- Compile the new modules:

ORP.Compile LSPhConstants.Mod/s RS232.Mod/s ~
ORP.Compile LSPhORS.Mod/s LSPhORB.Mod/s ~
ORP.Compile LSPhORG.Mod/s LSPhORP.Mod/s ~
ORP.Compile LSPhServer.Mod/s ~

- Restart the system. Maybe auto-run the `LSPhServer.Run` command.

- Use your newly created system with an Oberon Language Server, and enjoy the features.
