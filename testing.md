# Testing Guide

Note: For test suite structure and local patterns, see `tests/README.md`.

This repository uses a unified PowerShell runner to execute all automated test suites and enforce language-specific coverage thresholds. The workflow is designed to be idempotent and portable across Windows and POSIX hosts that have [PowerShell 7+](https://learn.microsoft.com/powershell/scripting/install/installing-powershell) available.

## Prerequisites

- **Python 3.10 or 3.11** with `pip`
- **PowerShell 7+** (`pwsh` on macOS/Linux, `powershell` on Windows)
- **Node.js 18+** (optional, required only if JavaScript tests are configured)
- Git for source control operations

> Tip: Developers on Windows can run everything from an elevated PowerShell prompt. macOS/Linux users can rely on the bundled `pwsh` binary that ships with GitHub Codespaces and GitHub-hosted runners.

## Canonical Commands

| Goal | Command |
| --- | --- |
| Run every configured suite | `make test` |
| Python-only tests | `make test:py` |
| PowerShell-only tests | `make test:ps` |
| JavaScript-only tests (if configured) | `make test:js` |
| CI equivalent | `make ci` |
| Direct runner invocation | `pwsh -File scripts/run_all_tests.ps1` |

`make test` is the single entry point for local and CI execution. It delegates to `scripts/run_all_tests.ps1`, which orchestrates each suite and writes machine-readable artifacts under `.reports/`.

## Runner Behaviour

`scripts/run_all_tests.ps1` performs the following steps:

1. Ensures `.reports/` sub-directories exist (`python/`, `powershell/`, `js/`).
2. Installs missing dependencies:
   - Python: `pip install -e .[test]` (or `requirements-dev.txt` if present).
   - PowerShell: installs [Pester 5](https://github.com/pester/Pester) on demand.
   - Node: runs `npm install --ignore-scripts` only when a `test` script exists in `package.json`.
3. Executes language suites:
   - **Python:** Runs the curated security unit tests with coverage limited to `security/auth.py` and `security/rbac.py`. Coverage XML is emitted to `.reports/python/coverage/coverage.xml` and JUnit XML to `.reports/python/junit/pytest-results.xml` with a hard gate of ≥85%.
   - **PowerShell:** Loads `pester.config.psd1`, runs `Invoke-Pester` against `tests/pester`, and enforces ≥85% coverage of `scripts/TradingOps/TradingOps.psm1`. Results are saved to `.reports/powershell/...` (JaCoCo + NUnit XML).
   - **Node:** If a `test` script exists, executes it with JUnit (`jest-junit`) and coverage enabled, writing to `.reports/js/`.
4. Aggregates a Markdown summary in `.reports/summary.md` and fails fast when any suite or coverage gate fails.

### Optional Flags

The runner accepts switches to skip suites when iterating locally:

```powershell
pwsh -File scripts/run_all_tests.ps1 -SkipPython -SkipNode   # PowerShell only
pwsh -File scripts/run_all_tests.ps1 -SkipPowerShell          # Python + Node
```

## Coverage Expectations

- **Python:** ≥85% for the measured security modules. Broader packages currently fall below this bar—see `docs/development/test-gap-report\.md` for remediation priorities.
- **PowerShell:** ≥85% for the TradingOps module.
- **Node:** No JavaScript coverage gate is configured yet because the workspace lacks an automated test script.

Coverage XML (Cobertura/JaCoCo) and JUnit XML are produced for every suite and are uploaded by CI for auditability.

## Continuous Integration

`.github/workflows/tests.yml` mirrors the local runner. It fans out into Python (3.10 & 3.11 on Ubuntu), PowerShell (Windows), and Node (Ubuntu) jobs. Each job uploads its artifacts from `.reports/` and enforces the same coverage thresholds to keep local and CI behaviours aligned.

## Adding New Tests

1. Place Python tests under `tests/unit/` using `test_*.py` naming and update/extend fixtures in `tests/conftest.py` when necessary.
2. Add PowerShell tests under `tests/pester/` with `*.Tests.ps1`. Update `pester.config.psd1` to include new modules for coverage.
3. If JavaScript tests are introduced, add them under an appropriate directory (e.g., `frontend/tests/`) and wire a `test` script into `package.json`.
4. Run `make test` before committing to regenerate reports and confirm coverage gates.

## Reports Directory Layout

```
.reports/
  baseline/            # Archived historic snapshots
  python/
    coverage/          # coverage.xml
    junit/             # pytest-results.xml
  powershell/
    coverage/          # pester-coverage.xml (JaCoCo)
    junit/             # pester-results.xml (NUnit)
  js/
    coverage/          # lcov, coverage.json, etc. (future use)
    junit/             # jest-results.xml (future use)
  summary.md           # human-readable run summary
```

The runner overwrites artifacts on each invocation. If you need historical trends, copy the relevant files into a timestamped directory under `.reports/baseline/` before re-running.

