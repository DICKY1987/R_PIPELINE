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

