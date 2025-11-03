# Branch protections

Protected branches enforce:

- Required status checks: `merge-train`, `SafePatch`.
- Required reviews from CODEOWNERS (docs, scripts).
- Rerere cache retention and artifact uploads per `.merge-policy.yaml`.
- Auto-deletion of merged branches via GitHub settings.

Configure protections using `scripts/github/Configure-BranchProtection.ps1`.
