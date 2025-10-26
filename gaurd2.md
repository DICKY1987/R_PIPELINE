1) Ask for code the right way (spec-first prompts)

Give the model a tiny spec with non-negotiables and a success test.

Mini template (copy/paste for PowerShell or Python):

ROLE: Senior {language} engineer. Output one file only.

TASK: Implement {functionality}.

CONSTRAINTS:
- OS: Windows {version}; Shell: {PowerShell 5.1/7 or Python 3.11}.
- No external network calls.
- Fail fast: exit non-zero on any error.
- Idempotent, re-entrant.

INPUTS/OUTPUTS:
- Inputs: {args, env vars, file paths}
- Output: {exact file(s) or stdout format}

STYLE/GUARDS:
- {PowerShell}: Set-StrictMode -Version Latest; $ErrorActionPreference='Stop'; [CmdletBinding(SupportsShouldProcess=$true)] with -WhatIf.
- {Python}: type hints, argparse, logging, no prints except final result, raise on error.

TESTS TO PASS (golden cases):
1. Given {input A} → expect {output A}
2. Given {input B} → expect {output B}

DELIVERABLE:
- Code only, no prose.

2) Make the script itself “self-defensive”

Ask the AI to include these patterns by default:

PowerShell skeleton (bulletproof starter):

#Requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
[CmdletBinding(SupportsShouldProcess = $true)]
param(
  [Parameter(Mandatory)][ValidateScript({ Test-Path $_ -PathType Container })][string]$Root,
  [ValidateSet('Info','Warn','Error')][string]$LogLevel='Info'
)
trap { Write-Error $_; exit 1 }

function Invoke-Main {
  try {
    # core logic here
  } catch {
    Write-Error ("FATAL: " + $_.Exception.Message)
    exit 1
  }
}
if ($PSCmdlet.ShouldProcess($Root, "Run job")) { Invoke-Main }


Python skeleton (safe defaults):

from __future__ import annotations
import argparse, logging, sys
from pathlib import Path

def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser()
    p.add_argument("--root", required=True, type=Path)
    return p.parse_args()

def setup_logging():
    logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")

def main() -> int:
    args = parse_args()
    setup_logging()
    try:
        # core logic here
        return 0
    except Exception as e:
        logging.error("FATAL: %s", e)
        return 1

if __name__ == "__main__":
    sys.exit(main())

3) Add instant, local validators (pre-commit)

Automate checks so bad code can’t land.

.pre-commit-config.yaml

repos:
- repo: https://github.com/psf/black
  rev: 24.8.0
  hooks: [{id: black}]
- repo: https://github.com/astral-sh/ruff-pre-commit
  rev: v0.6.9
  hooks: [{id: ruff}]
- repo: https://github.com/pre-commit/mirrors-mypy
  rev: v1.11.2
  hooks: [{id: mypy, additional_dependencies: ["types-PyYAML"]}]
- repo: https://github.com/pre-commit/pre-commit-hooks
  rev: v4.6.0
  hooks:
    - {id: check-added-large-files}
    - {id: check-merge-conflict}
    - {id: end-of-file-fixer}


PowerShell lint/test equivalents:

Use PSScriptAnalyzer (Invoke-ScriptAnalyzer) for style & common errors.

Add Pester unit tests for key behaviors.

4) Ship tests with every request

Give the AI small, runnable tests so it “aims” correctly.

Pester test (PowerShell):

# tests/Script.Tests.ps1
Set-StrictMode -Version Latest
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$script = Join-Path $here "..\script.ps1"

Describe "script.ps1" {
  It "handles basic run" {
    $out = & $script -Root $env:TEMP -WhatIf
    $LASTEXITCODE | Should -Be 0
  }
}


pytest (Python):

# tests/test_main.py
from subprocess import run
def test_cli_help():
    r = run(["python","script.py","--help"], capture_output=True, text=True)
    assert r.returncode == 0
    assert "usage:" in r.stdout

5) Prefer “edit this file” diffs over “write a new script”

Ask AI to produce minimal diffs for an existing file (great with Aider/Code assistants). This avoids regressions and keeps context.

Prompt add-on:

ONLY return a unified diff (git patch) against {path/to/file}. No new files.

6) Constrain the environment explicitly

Specify versions (PowerShell 5.1 vs 7; Python 3.11.x).

Provide sample real paths (Windows paths with spaces), and require the code to handle them.

List forbidden APIs (e.g., no Write-Host for core outputs, no print except final result).

7) Provide real fixtures (“golden data”)

Attach a tiny test corpus (2–3 files/dirs) and say “the code will be validated against this exact layout.” This eliminates guesswork.

8) Use CI as your backstop

Have GitHub Actions run linters + tests on every PR.

.github/workflows/ci.yml

name: CI
on: [push, pull_request]
jobs:
  py:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with: { python-version: "3.11" }
      - run: pip install -U pip black ruff mypy pytest
      - run: black --check .
      - run: ruff check .
      - run: mypy .
      - run: pytest -q
  ps:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4
      - run: Install-Module Pester,PSScriptAnalyzer -Scope CurrentUser -Force
        shell: pwsh
      - run: Invoke-ScriptAnalyzer -Path . -Recurse -Severity Warning
        shell: pwsh
      - run: Invoke-Pester -CI
        shell: pwsh

9) Teach the model your house style (once)

Keep a short “Project Conventions” file (naming, logging, error handling, argument patterns). Paste it into the prompt or link it each time. The more consistent your standards, the fewer errors.

10) Iterate in tiny steps

Ask for:

“Scaffold only” (just argparse/param blocks + logging).

“One function implemented.”

“Add tests.”

“Wire function into CLI.”
This staged approach dramatically lowers error rate.

TL;DR checklist you can pin

 Spec-first prompt with constraints + golden tests

 Safe skeleton (StrictMode / type hints / argparse / logging)

 Pre-commit (black, ruff, mypy) + PSScriptAnalyzer

 Pester/pytest smoke tests included

 Minimal diffs over full rewrites

 Versions & paths spelled out

 Tiny real fixtures in the repo

 CI on every push/PR

 One-page “Project Conventions”

 Ship changes in small, testable steps

If you want, I can generate a ready-to-drop start