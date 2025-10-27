# Agent Guidance for This Repo

Scope: Root and all subdirectories.

Follow these rules when proposing or applying changes:

1) Read and obey
- `docs/STYLEGUIDE.md`
- `docs/TEST_POLICY.md`
- `docs/SAFE_PATCH_RULES.md`
- `docs/MODULE_MAP.md`
- `docs/EXEMPLARS/*`
- `docs/templates/pwsh/*`, `docs/templates/pester/*`

2) Tests-first workflow
- Start with a minimal failing test under `tests/` using the appropriate template.
- Then apply the smallest implementation diff to pass it.

3) Constraints
- Python: full type hints; stdlib-first; structured logging; no broad try/except.
- PowerShell: `Set-StrictMode -Version Latest`; `[CmdletBinding()]`; parameter validation; state-change modules respect `-WhatIf`/`-Confirm` via `SupportsShouldProcess`.

4) Deliverables for each change
- A unified diff for the failing/updated test.
- A unified diff for the minimal implementation.
- A rubric checklist with all PASS based on `docs/AI_RUBRIC.md`.

5) Local verification
- Run `pwsh -File tools/Verify.ps1` and ensure it is green before asking to commit.

