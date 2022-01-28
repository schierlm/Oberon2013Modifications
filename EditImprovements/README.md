EditImprovements - Edit.Locate and ~.Search display the target location in the first line of the viewer

Description
-----------

When invoking them on small viewers, Edit.Locate and ~.Search sometimes position the text in the viewer that the target location is beyond the end of the viewer.
This patch insures that the target location will always be at the first line of the viewer.

Installation
------------

- Apply [`Edit.patch`](Edit.patch) to `Edit.Mod`.

- Recompile `Edit.Mod`:

      ORP.Compile Edit.Mod ~