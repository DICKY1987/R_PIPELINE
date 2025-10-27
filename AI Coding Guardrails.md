AI Coding Guardrails — One-File Instruction Pack

How to make Claude Code, Aider, and Codex-style CLIs instantly write better, modular, test-first code in your repo.

0) Objective & Principle

Goal: Make every AI session produce small, typed, test-first, policy-compliant diffs that fit your modular templates.
Principle: (a) Constrain the target with rules/templates; (b) Feed exemplars; and (c) Demand a self-check before final output.

1) Quick-Start Scaffolder (run once)

Run this PowerShell to create all docs + template folders and seed them with minimal content you can customize.

# bootstrap_guardrails.ps1
$root = (Get-Location).Path
$paths = @(
  "docs", "docs/EXEMPLARS", "docs/templates/pwsh", "docs/templates/pester"
)
$paths | % { New-Item -ItemType Directory -Force -Path (Join-Path $root $_) | Out-Null }

@"
# STYLEGUIDE

## Global
- Small diffs. No dead code. Keep functions ≤30 LOC when possible.
- Logging not print. No secrets in code. No `eval`, no `shell=True`.

## Python
- Full type hints; no mutable default args; prefer stdlib (`pathlib`, `subprocess.run(..., check=True)`).
- Tests: pytest; add regression tests for fixes.

## PowerShell
- `Set-StrictMode -Version Latest`; `[CmdletBinding()]`; parameter validation attrs.
- Side effects only in *State-Change* modules, must implement `SupportsShouldProcess`.
"@ | Set-Content -NoNewline -Path "docs/STYLEGUIDE.md"

@"
# TEST_POLICY

- **Tests first.** Write/adjust a minimal failing test, then the smallest diff to go green.
- Coverage target: changed lines & public functions touched by this change.
- Add edge cases for null/empty, error paths, and boundary conditions.
"@ | Set-Content -NoNewline -Path "docs/TEST_POLICY.md"

@"
# SAFE_PATCH_RULES

- If `# BEGIN EDITABLE` / `# END EDITABLE` tags exist, edit only inside them.
- **Deliverables:** a single **unified diff** + the rubric checklist.
- No new dependencies without a 1–2 line justification.
"@ | Set-Content -NoNewline -Path "docs/SAFE_PATCH_RULES.md"

@"
# AI_RUBRIC (10 checks)

1 Correctness & edge cases
2 Types (or param validation)
3 Error handling (no broad catches)
4 Idempotence (when applicable)
5 ShouldProcess / -WhatIf (PS side-effects)
6 Logging (structured; no print)
7 Security (no secrets/eval/shell True)
8 Style (matches STYLEGUIDE)
9 Tests quality (fail first → pass)
10 Diff size & focus

**Return:** PASS/FAIL per item. If any FAIL → fix → re-run.
"@ | Set-Content -NoNewline -Path "docs/AI_RUBRIC.md"

@"
# MODULE_MAP (excerpt)

| Module                    | Purpose                                   | Public APIs (sig)                | Invariants / Pitfalls               |
|--------------------------|--------------------------------------------|----------------------------------|-------------------------------------|
| user/transform_user.ps1  | Normalize user spec (pure)                 | Convert-UserSpec([pscustomobject]) -> [pscustomobject] | No I/O; deterministic; keep keys    |
| user/get_hr_user.ps1     | Acquire HR user (read-only external)       | Get-HrUser([string]) -> [pscustomobject]               | Timeout/retry; sanitize null fields |
| user/set_user_home.ps1   | Ensure home/ACL (state-change)             | Set-UserHome([string])           | Idempotent; ShouldProcess; -WhatIf  |
"@ | Set-Content -NoNewline -Path "docs/MODULE_MAP.md"

@"
# EXEMPLAR: Python (pure transformation)
from __future__ import annotations
from typing import Dict, Any

def normalize_spec(spec: Dict[str, Any]) -> Dict[str, Any]:
    \"\"\"Normalize user spec.
    Args: spec: raw dict
    Returns: normalized dict
    Raises: ValueError on missing 'id'
    \"\"\"
    if 'id' not in spec or not spec['id']:
        raise ValueError('id required')
    name = (spec.get('name') or '').strip()
    return {'id': str(spec['id']).strip(), 'name': name or 'UNKNOWN'}

# pytest
def test_normalize_spec_success():
    assert normalize_spec({'id': '42', 'name': '  Ada '}) == {'id':'42','name':'Ada'}

def test_normalize_spec_missing_id_raises():
    import pytest
    with pytest.raises(ValueError): normalize_spec({'name':'Ada'})
"@ | Set-Content -NoNewline -Path "docs/EXEMPLARS/py_normalize_spec.py"

@"
# EXEMPLAR: PowerShell (advanced function, pure)
Set-StrictMode -Version Latest
function Convert-UserSpec {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][pscustomobject]$UserSpec
  )
  if (-not $UserSpec.id) { throw 'id required' }
  $name = ($UserSpec.name ?? '').Trim()
  [pscustomobject]@{ id = ""$($UserSpec.id)""; name = ($name ? $name : 'UNKNOWN') }
}

# Pester v5
Describe 'Convert-UserSpec' {
  It 'normalizes name' {
    $out = Convert-UserSpec -UserSpec ([pscustomobject]@{id='42';name=' Ada '})
    $out.name | Should -Be 'Ada'
  }
  It 'throws on missing id' {
    { Convert-UserSpec -UserSpec ([pscustomobject]@{name='Ada'}) } | Should -Throw
  }
}
"@ | Set-Content -NoNewline -Path "docs/EXEMPLARS/ps_convert_user_spec.ps1"

@"
# TEMPLATE: 01_Transformation.ps1.tmpl
Set-StrictMode -Version Latest
function <Verb-Noun> {
  [CmdletBinding()]
  param(
    # <typed params with validation>
  )
  <# Purpose: pure transformation
     Inputs/Outputs: <types>
     Preconditions/Postconditions: <list>
     Errors: throw specific, actionable messages
  #>
  # BEGIN EDITABLE
  throw 'not implemented'
  # END EDITABLE
}
"@ | Set-Content -NoNewline -Path "docs/templates/pwsh/01_Transformation.ps1.tmpl"

@"
# TEMPLATE: 03_StateChange.ps1.tmpl
Set-StrictMode -Version Latest
function <Verb-Noun> {
  [CmdletBinding(SupportsShouldProcess)]
  param(
    # <typed params with validation>
  )
  <# Purpose: state change (idempotent)
     Idempotence: detect existing correct state, no-op if matched
     ShouldProcess: respect -WhatIf/-Confirm
  #>
  if (-not $PSCmdlet.ShouldProcess('<target>','<action>')) { return }
  # BEGIN EDITABLE
  throw 'not implemented'
  # END EDITABLE
}
"@ | Set-Content -NoNewline -Path "docs/templates/pwsh/03_StateChange.ps1.tmpl"

@"
# TEMPLATE: 01_Transformation.Tests.ps1.tmpl
Describe '<Verb-Noun>' {
  It 'handles happy path' { <call> | Should -Be <expected> }
  It 'handles edge case'  { { <call-bad> } | Should -Throw }
}
"@ | Set-Content -NoNewline -Path "docs/templates/pester/01_Transformation.Tests.ps1.tmpl"

@"
# Verify.ps1 (local gate)
Set-StrictMode -Version Latest
Write-Host 'Running PowerShell checks...' 
if (Get-Command Invoke-ScriptAnalyzer -ErrorAction SilentlyContinue) {
  Invoke-ScriptAnalyzer -Path . -Recurse -Severity Warning,Error -EnableExit
}
Write-Host 'Running Pester...' 
if (Get-Command Invoke-Pester -ErrorAction SilentlyContinue) {
  Invoke-Pester -CI -Output Detailed
}
Write-Host 'Running Python checks...'
if (Get-Command ruff -ErrorAction SilentlyContinue) { ruff check . ; if ($LASTEXITCODE) { exit $LASTEXITCODE } }
if (Get-Command mypy -ErrorAction SilentlyContinue) { mypy . ; if ($LASTEXITCODE) { exit $LASTEXITCODE } }
if (Get-Command pytest -ErrorAction SilentlyContinue) { pytest -q ; if ($LASTEXITCODE) { exit $LASTEXITCODE } }
"@ | Set-Content -NoNewline -Path "tools/Verify.ps1"

Write-Host "Scaffold complete. Customize docs/templates and start using the prompts."

2) Session Kickoff — Copy/Paste Prompts
2.1 Universal “Template Gate” (paste first in any app)
You are working INSIDE THIS REPO.

1) Read once and obey strictly:
   - docs/STYLEGUIDE.md
   - docs/TEST_POLICY.md
   - docs/SAFE_PATCH_RULES.md
   - docs/MODULE_MAP.md
   - docs/EXEMPLARS/*  (few-shot style)
   - docs/templates/pwsh/<Category>.ps1.tmpl
   - docs/templates/pester/<Category>.Tests.ps1.tmpl

2) Tests-first: write/adjust a minimal failing test using the matching template; then ONE small implementation diff to pass it.

3) Constraints
- Python: full type hints; no broad try/except; prefer stdlib; logging not print.
- PowerShell: Set-StrictMode Latest; [CmdletBinding()]; param validation; 
  *State-Change* modules are idempotent and implement SupportsShouldProcess with -WhatIf/-Confirm.

4) Return ONLY:
A) the failing/changed test (unified diff section)
B) one unified diff for the implementation
C) a 10-line rubric (docs/AI_RUBRIC.md) with PASS everywhere (fix and re-run until PASS)

2.2 App-specific “starter line” to add after the Template Gate

Claude Code:
Category: State-Change; Target: src/Public/Set-UserHome.ps1; Goal: add -WhatIf and idempotence check; Edge cases: existing path, ACL mismatch.

Aider:
Category: Transformation; Target: src/Private/Convert-UserSpec.ps1; Goal: normalize names & ids; Edge cases: null/empty name, missing id.

Codex-style CLI:
Category: Validation; Target: src/Public/Test-UserPolicy.ps1; Goal: assert required fields are present; Output: machine-readable Pass/Fail object.

Keep scope to one file / function + its tests for highest quality.

3) Micro-Policies to Paste into docs/STYLEGUIDE.md

Types: all new/changed public APIs are fully typed (or param-validated in PS).

Errors: no broad catches; raise/throw with actionable messages.

I/O: none in pure logic; inject collaborators; test with fakes/mocks.

Logging: structured; never print / noisy Write-Host.

Security: no eval, no shell=True, no secrets in code; read from env.

Dependencies: prefer stdlib; justify any new dep in 1–2 lines in PR.

Tests: bugfix → add regression test; new feature → success + edge cases.

Smallness: functions ≤30 LOC when possible; single responsibility.

4) Modular Templates (how AI should structure code)

Your Engineering Framework for MODULAR CODE maps neatly to five categories. Put these templates under docs/templates/pwsh/ and tell the AI to copy their structure.

Transformation (pure) — 01_Transformation.ps1.tmpl

No side effects; deterministic; throws specific errors.

Test template: unit tests only.

Acquisition (read-only external) — 02_Acquisition.ps1.tmpl

Read external sources; normalize/sanitize; add timeout/retry; no mutation.

Test template: mock external calls.

State-Change (idempotent) — 03_StateChange.ps1.tmpl

Make change only if needed; implement SupportsShouldProcess; honor -WhatIf/-Confirm.

Test template: -WhatIf verification + “already correct” no-op.

Validation (assert invariants) — 04_Validation.ps1.tmpl

No fixes; return machine-readable pass/fail with reasons.

Test template: good/bad samples.

Orchestrator (thin glue) — 05_Orchestrator.ps1.tmpl

Compose the above; no business logic; structured logging; mock sub-calls in tests.

Tip: Add a tiny “mini-exemplar” at the end of each template: a perfect param block + one guard + one log line.

5) Example “Fail-then-Pass” Flow (what the AI should output)

(A) Failing Pester test (diff section)

diff --git a/tests/Convert-UserSpec.Tests.ps1 b/tests/Convert-UserSpec.Tests.ps1
+Describe 'Convert-UserSpec' {
+  It 'normalizes name and id' {
+    $out = Convert-UserSpec -UserSpec ([pscustomobject]@{id=' 42 '; name=' Ada '})
+    $out | Should -BeOfType pscustomobject
+    $out.id   | Should -Be '42'
+    $out.name | Should -Be 'Ada'
+  }
+}


(B) Minimal implementation (diff section)

diff --git a/src/Private/Convert-UserSpec.ps1 b/src/Private/Convert-UserSpec.ps1
+Set-StrictMode -Version Latest
+function Convert-UserSpec {
+  [CmdletBinding()]
+  param([Parameter(Mandatory)][pscustomobject]$UserSpec)
+  if (-not $UserSpec.id) { throw 'id required' }
+  $id = "$($UserSpec.id)".Trim()
+  $name = ("" + ($UserSpec.name ?? '')).Trim()
+  [pscustomobject]@{ id = $id; name = ($name ? $name : 'UNKNOWN') }
+}


(C) Rubric (PASS)

1 Correctness PASS
2 Types/Validation PASS
3 Errors PASS
4 Idempotence N/A
5 ShouldProcess N/A
6 Logging PASS
7 Security PASS
8 Style PASS
9 Tests Quality PASS
10 Diff Size PASS

6) Local Guardrail Runner (call this after each AI diff)

Add to repo as tools/Verify.ps1 (already scaffolded above). Run:

pwsh -File .\tools\Verify.ps1


Expected behavior: block locally on PSScriptAnalyzer/Pester/ruff/mypy/pytest failures.
(Use the same in CI as your backstop.)

7) How to “aim” the model at the right spot (context recipe)

When you start a task, append a one-liner after the Template Gate:

Transformation:
Category: Transformation; File: src/Private/Convert-UserSpec.ps1; Signature: (pscustomobject) -> (pscustomobject); Invariant: no I/O; Edge cases: missing id, empty name, whitespace id.

Acquisition:
Category: Acquisition; File: src/Public/Get-HrUser.ps1; Signature: (string id) -> (pscustomobject); Invariant: read-only; Edge cases: 404, timeouts, null fields.

State-Change:
Category: State-Change; File: src/Public/Set-UserHome.ps1; Signature: (string user) -> void; Invariant: idempotent; Must: ShouldProcess; Edge cases: existing path, ACL mismatch.

Validation:
Category: Validation; File: src/Public/Test-UserPolicy.ps1; Output: [pscustomobject] with Pass:bool, Reasons:string[]; Edge cases: missing fields, empty arrays.

Orchestrator:
Category: Orchestrator; File: scripts/New-UserOnboard.ps1; Call order: Acquisition→Validation→State-Change→Transformation outputs as needed; No business logic.

8) Daily Usage Checklist (per AI session)

Paste Template Gate → add one-line scope.

Demand: failing test diff → minimal implementation diff → rubric PASS.

Run .\tools\Verify.ps1.

Commit only if green; otherwise iterate (the model must fix until rubric PASS).

9) Language-Specific Nudges (copy into STYLEGUIDE)

Python: full type hints; dataclasses if appropriate; pathlib; subprocess.run(..., check=True); no mutable defaults; explicit __all__.

PowerShell: Set-StrictMode -Version Latest; [CmdletBinding()]; parameter validation; State-Change implements SupportsShouldProcess and honors -WhatIf/-Confirm; Pester v5 with clear Because messages.