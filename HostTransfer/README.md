HostTransfer - Allow systems within emulators to copy files from/to the host

Description
-----------

**NOTE**: Unlike other modifications, this modification is not standalone. It requires that
you applied the [HardwareEnumerator](../HardwareEnumerator/README.md) modification,
before this modification.

This modification provides a way for Oberon running inside an emulator to copy files
to and from the host. Files copied from the host may either be stored in the Oberon
filesystem or dumped to the System Log.

Additionally, commands that do not require input can be executed on the host and the output
is returned to the Oberon guest.

Filenames on the host can either be given as bare names (if they follow Oberon's filename convention),
or strings delimited by either single or double quotes, or "quoted strings" (as used in A2/Bluebottle):
A backslash followed by any letter followed by a single or double quotation mark (= initial sequence),
followed by the quoted string, followed by the initial sequence in reverse order.

Installation
------------

- Apply [HardwareEnumerator](../HardwareEnumerator/README.md), if not already applied.

- Push [`HostTransfer.Mod.txt`](HostTransfer.Mod.txt) and [`HostTransfer.Tool.txt`](HostTransfer.Tool.txt).

- Compile the new module:

      ORP.Compile HostTransfer.Mod/s ~

- Use the commands in [`HostTransfer.Tool.txt`](HostTransfer.Tool.txt).
