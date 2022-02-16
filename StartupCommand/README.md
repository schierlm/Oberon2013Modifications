StartupCommand - Run a command (from System.Tool) when Oberon starts

Description
-----------

With the advent of the hardware enumerator, more and more runtime features
(e.g. display resolution, seamless resize) become configurable. However,
in the original Oberon system, such configuration is only possible by modifying
one of the startup modules and recompiling.

It would be helpful to have the possibility to run a command
(or [script](../Scripting/README.md)) at startup.

This modifications implements a very minimal approach. If the file `System.Tool`
starts with the literal String `@Startup:`, the next command gets automatically
executed on startup.

Installation
------------

- Apply [`StartupCommand.patch`](StartupCommand.patch) to `System.Mod`.

- Compile the patched module:

    ORP.Compile System.Mod ~

- Optionally add a startup command to `System.Tool`.

- Restart the system.
