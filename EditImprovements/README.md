EditImprovements - Edit.Locate and ~.Search display the target location in the first line of the viewer

Description
-----------

When invoking them on small viewers, Edit.Locate and ~.Search sometimes position the text in the viewer that the target location is beyond the end of the viewer.
This patch insures that the target location will always be at the first line of the viewer.

A second version of the patch is provided, that adds quite some complexity, but tries to position the target location at about 66% of the viewer's height.

Installation
------------

- Apply [`Edit.1r.patch`](Edit.1r.patch) to `Edit.Mod`.

- Optionally apply [`Edit.3r.patch`](Edit.3r.patch) to `Edit.Mod`.

- In case you want to use the [UTF8CharsetLite](../UTF8CharsetLite/README.md) modification, apply [`EditU.0.patch`](EditU.0.patch) to `EditU.Mod`;
  optionally create `EditU.3r.patch` by applying [`EditU.3r.patch.patch`](EditU.3r.patch.patch) to `Edit.3r.patch` and apply it to `EditU.Mod`.

- Recompile `Edit.Mod` and optionally `EditU.Mod`:

      ORP.Compile Edit.Mod EditU.Mod ~