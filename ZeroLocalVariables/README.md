ZeroLocalVariables - Zero local variables to avoid memory corruption due to uninitialized variables

Description
-----------

Oberon does not initialize local variables, so if you do not do it yourself, expect
funny values in them. However, this may lead to memory corruption if a local pointer
variable is not initialized.

Therefore, use a simplistic approach and just initialize all local variables
with zeroes.

I know that this fix is (mildly speaking) controversial, for arguments see the
discussion starting at <http://lists.inf.ethz.ch/pipermail/oberon/2019/thread.html#13120>.

But I've used this patch for more than 5 years now and it was really helpful, so I'll
include it here. Before publishing your modules, you should still test them without
this patch applied (or better, test them on a vanilla Oberon system).

Installation
------------

- Apply [`ZeroLocalVariables.patch`](ZeroLocalVariables.patch) to `ORG.Mod`.

- Compile the patched module:

    ORP.Compile ORG.Mod ~

- Restart the system.

- Recompile any modules where you want local variables to be initialized.