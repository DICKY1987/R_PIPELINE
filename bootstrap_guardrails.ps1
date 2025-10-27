Param(
  [switch] $ForceOverwrite
)

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'
$root = (Get-Location).Path
$paths = @(
  "docs",
  "docs/EXEMPLARS",
  "docs/templates/pwsh",
  "docs/templates/pester",
  "tools"
)
$paths | ForEach-Object { New-Item -ItemType Directory -Force -Path (Join-Path $root $_) | Out-Null }

function Set-FileIfMissing {
  param(
    [Parameter(Mandatory)] [string] $Path,
    [Parameter(Mandatory)] [string] $Content
  )
  if (Test-Path $Path -PathType Leaf -and -not $ForceOverwrite) { return }
  $dir = Split-Path -Parent $Path
  if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
  Set-Content -Path $Path -Value $Content -NoNewline
}

Set-FileIfMissing -Path "docs/STYLEGUIDE.md" -Content @'
# STYLEGUIDE

## Global
- Small diffs. No dead code. Keep functions <= 30 LOC when possible.
- Use logging (structured) not print. No secrets checked into code. No `eval`, no `shell=True`.

## Python
- Full type hints; no mutable default args; prefer stdlib (`pathlib`, `subprocess.run(..., check=True)`).
- Tests use `pytest`; add a regression test for every bug fix.
- Prefer `dataclasses` when appropriate; explicit `__all__` in packages.

## PowerShell
- `Set-StrictMode -Version Latest`; `[CmdletBinding()]`; parameter validation attributes on public parameters.
- Side effects only in State-Change modules; they must implement `SupportsShouldProcess` and honor `-WhatIf`/`-Confirm`.
- Error messages are actionable and specific; avoid broad `try { } catch { }` without filtering.

## Micro-Policies
- Types: all new/changed public APIs are fully typed (Python) or param-validated (PowerShell).
- Errors: no broad catches; raise/throw specific messages.
- I/O: none in pure logic; inject collaborators; test with fakes/mocks.
- Logging: structured; never noisy `Write-Host` in libraries.
- Security: no `eval`, no `shell=True`, no secrets; read sensitive values from environment.
- Dependencies: prefer stdlib; justify any new dependency with a 1–2 line note in PRs.
- Tests: bugfix => add regression test; new feature => success + edge cases.
- Smallness: functions <= 30 LOC when possible; single responsibility.
'@

Set-FileIfMissing -Path "docs/TEST_POLICY.md" -Content @'
# TEST_POLICY

- Tests first. Write/adjust a minimal failing test, then the smallest diff to go green.
- Coverage target: changed lines and public functions touched by this change.
- Add edge cases for null/empty inputs, error paths, and boundary conditions.
'@

Set-FileIfMissing -Path "docs/SAFE_PATCH_RULES.md" -Content @'
# SAFE_PATCH_RULES

- If `# BEGIN EDITABLE` / `# END EDITABLE` tags exist, edit only inside them.
- Deliverables per change: a single unified diff plus the rubric checklist.
- No new dependencies without a 1–2 line justification.
'@

Set-FileIfMissing -Path "docs/AI_RUBRIC.md" -Content @'
# AI_RUBRIC (10 checks)

1 Correctness & edge cases
2 Types (or parameter validation)
3 Error handling (no broad catches)
4 Idempotence (when applicable)
5 ShouldProcess / -WhatIf (PS side-effects)
6 Logging (structured; no print)
7 Security (no secrets/eval/shell True)
8 Style (matches STYLEGUIDE)
9 Tests quality (fail first → pass)
10 Diff size & focus

Return: PASS/FAIL per item. If any FAIL → fix → re-run.
'@

Set-FileIfMissing -Path "docs/MODULE_MAP.md" -Content @'
# MODULE_MAP (excerpt)

| Module                   | Purpose                            | Public APIs (sig)                                  | Invariants / Pitfalls                 |
|--------------------------|------------------------------------|----------------------------------------------------|---------------------------------------|
| user/transform_user.ps1  | Normalize user spec (pure)         | Convert-UserSpec([pscustomobject]) -> [pscustomobject] | No I/O; deterministic; keep keys      |
| user/get_hr_user.ps1     | Acquire HR user (read-only external) | Get-HrUser([string]) -> [pscustomobject]            | Timeout/retry; sanitize null fields   |
| user/set_user_home.ps1   | Ensure home/ACL (state-change)     | Set-UserHome([string])                              | Idempotent; ShouldProcess; -WhatIf    |
'@

Set-FileIfMissing -Path "docs/EXEMPLARS/py_normalize_spec.py" -Content @'
from __future__ import annotations
from typing import Dict, Any


def normalize_spec(spec: Dict[str, Any]) -> Dict[str, Any]:
    """Normalize a user spec.

    Args:
        spec: Raw input mapping.
    Returns:
        Normalized mapping with 'id' and 'name'.
    Raises:
        ValueError: If 'id' is missing or empty.
    """
    if "id" not in spec or not spec["id"]:
        raise ValueError("id required")
    name = str(spec.get("name") or "").strip()
    return {"id": str(spec["id"]).strip(), "name": name or "UNKNOWN"}


# pytest
def test_normalize_spec_success() -> None:
    assert normalize_spec({"id": "42", "name": "  Ada "}) == {
        "id": "42",
        "name": "Ada",
    }


def test_normalize_spec_missing_id_raises() -> None:
    import pytest

    with pytest.raises(ValueError):
        normalize_spec({"name": "Ada"})
'@

Set-FileIfMissing -Path "docs/EXEMPLARS/ps_convert_user_spec.ps1" -Content @'
Set-StrictMode -Version Latest
function Convert-UserSpec {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][ValidateNotNull()] [pscustomobject] $UserSpec
  )
  if (-not $UserSpec.id) { throw 'id required' }
  $id = ("$($UserSpec.id)").Trim()
  $nameValue = if ($UserSpec.PSObject.Properties.Name -contains 'name' -and $null -ne $UserSpec.name) { [string]$UserSpec.name } else { '' }
  $name = $nameValue.Trim()
  [pscustomobject]@{ id = $id; name = (if ($name) { $name } else { 'UNKNOWN' }) }
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
'@

Set-FileIfMissing -Path "docs/templates/pwsh/01_Transformation.ps1.tmpl" -Content @'
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
'@

Set-FileIfMissing -Path "docs/templates/pwsh/02_Acquisition.ps1.tmpl" -Content @'
Set-StrictMode -Version Latest
function <Verb-Noun> {
  [CmdletBinding()]
  param(
    # <typed params with validation>
    # <dependency injection for external calls>
  )
  <# Purpose: acquisition (read-only external)
     Behavior: read external sources; normalize/sanitize; add timeout/retry; no mutation
     Errors: throw specific, actionable messages
  #>
  # BEGIN EDITABLE
  throw 'not implemented'
  # END EDITABLE
}
'@

Set-FileIfMissing -Path "docs/templates/pwsh/03_StateChange.ps1.tmpl" -Content @'
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
'@

Set-FileIfMissing -Path "docs/templates/pwsh/04_Validation.ps1.tmpl" -Content @'
Set-StrictMode -Version Latest
function <Verb-Noun> {
  [CmdletBinding()]
  param(
    # <typed params with validation>
  )
  <# Purpose: validation (assert invariants)
     Behavior: no fixes; return machine-readable pass/fail with reasons
  #>
  # BEGIN EDITABLE
  throw 'not implemented'
  # END EDITABLE
}
'@

Set-FileIfMissing -Path "docs/templates/pwsh/05_Orchestrator.ps1.tmpl" -Content @'
Set-StrictMode -Version Latest
function <Verb-Noun> {
  [CmdletBinding()]
  param(
    # <typed params with validation>
    # <injected collaborators for sub-calls>
  )
  <# Purpose: orchestrator (thin glue)
     Behavior: compose the above; no business logic; structured logging; mock sub-calls in tests
  #>
  # BEGIN EDITABLE
  throw 'not implemented'
  # END EDITABLE
}
'@

Set-FileIfMissing -Path "docs/templates/pester/01_Transformation.Tests.ps1.tmpl" -Content @'
Describe '<Verb-Noun>' {
  It 'handles happy path' {
    # Arrange/Act
    $result = <call>
    # Assert
    $result | Should -Be <expected>
  }
  It 'handles edge case'  {
    { <call-bad> } | Should -Throw -Because 'Edge case should throw actionable error'
  }
}
'@

Set-FileIfMissing -Path "docs/templates/pester/02_Acquisition.Tests.ps1.tmpl" -Content @'
Describe '<Verb-Noun>' {
  BeforeAll {
    # Example: Mock external dependency
    # Mock -CommandName Invoke-RestMethod -MockWith { return @{ id = '42'; name = 'Ada' } }
  }
  It 'returns normalized data' {
    $out = <call>
    $out | Should -Not -BeNullOrEmpty
  }
  It 'handles timeout/retry path' {
    { <call-timeout> } | Should -Throw
  }
}
'@

Set-FileIfMissing -Path "docs/templates/pester/03_StateChange.Tests.ps1.tmpl" -Content @'
Describe '<Verb-Noun>' {
  It 'honors -WhatIf' {
    <call -WhatIf>
    # Expect no exception and no side effects
    $true | Should -BeTrue
  }
  It 'no-ops when already correct' {
    # Arrange pre-existing correct state
    # Act
    <call>
    # Assert nothing changed
    $true | Should -BeTrue
  }
}
'@

Set-FileIfMissing -Path "docs/templates/pester/04_Validation.Tests.ps1.tmpl" -Content @'
Describe '<Verb-Noun>' {
  It 'passes for good sample' {
    $result = <call-good>
    $result.Pass    | Should -BeTrue
    $result.Reasons | Should -BeEmpty
  }
  It 'fails with reasons for bad sample' {
    $result = <call-bad>
    $result.Pass    | Should -BeFalse
    $result.Reasons | Should -Not -BeEmpty
  }
}
'@

Set-FileIfMissing -Path "docs/templates/pester/05_Orchestrator.Tests.ps1.tmpl" -Content @'
Describe '<Verb-Noun>' {
  BeforeAll {
    # Mock collaborators
    # Mock Get-HrUser -MockWith { [pscustomobject]@{ id='42'; name='Ada' } }
    # Mock Convert-UserSpec -MockWith { param($User) $User }
    # Mock Set-UserHome -MockWith { }
  }
  It 'wires sub-calls correctly' {
    <call>
    # Assert mocks were called as expected (Pester 5: Assert-MockCalled)
    # Assert-MockCalled Get-HrUser -Times 1
  }
}
'@

Set-FileIfMissing -Path "tools/Verify.ps1" -Content @'
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
'@

Write-Information "Scaffold complete. Customize docs/templates and start using the prompts."
