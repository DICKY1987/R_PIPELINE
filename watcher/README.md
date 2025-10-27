```markdown
# Watcher (Phase 1)

This directory contains the stream-lined file watcher and supporting tools that detect file changes and trigger quick validation checks.

Files
- build.ps1        : PowerShell build entrypoint (routes by extension and writes JSON results)
- watch.ps1        : FileSystemWatcher with debounce and batching
- watch.config.json: Configure debounce timing, include/exclude patterns, and action mapping
- watch.ignore     : Glob-style ignore patterns (PowerShell -like)
- py_check.py      : Python helper for syntax checks (used by build.ps1)
- tests/           : Pytest unit tests for Python helper
- test_sample.ps1  : Sample PowerShell file for Pester tests
- test_sample.Tests.ps1 : Pester tests for PowerShell sample

Quick start (Windows / PowerShell Core)
1. From repository root:
   pwsh ./watcher/watch.ps1 -Path . -DebounceMs 500

2. Run a one-shot scan:
   pwsh ./watcher/watch.ps1 -Path . -Once

3. Run the build directly for specific files:
   pwsh ./watcher/build.ps1 -Files ./path/to/file.py

CI (GitHub Actions) will run the tests defined under watcher/tests and PowerShell Pester tests.

Outputs
- JSON results: .runs/watch/<timestamp>.json
- JSONL per-run: .runs/watch/<timestamp>.jsonl
- Log file: watcher/watch.log

Notes
- build.ps1 will attempt to call SPEC-1 validation scripts if present under ../SPEC-1-AI-Upkeep-Suite-v2-Guardrails-MCP/scripts/validation
- The watcher is safe by default: it will not modify code, only run checks and produce structured results.
```