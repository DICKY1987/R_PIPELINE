# Contributing

Thank you for investing time in R_PIPELINE! This repository uses [pre-commit](https://pre-commit.com/) to keep changes clean and to surface errors before they land in CI. Please make sure these hooks are installed locally before opening a pull request.

## Quick start

1. Create and activate a Python environment that can install the tooling:
   ```bash
   python -m venv .venv
   source .venv/bin/activate
   pip install --upgrade pip
   ```
2. Install the project dependencies required for the hooks:
   ```bash
   pip install pre-commit commitizen black ruff
   pwsh -NoProfile -Command "Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -Force"
   ```
3. Install the hooks into your git configuration:
   ```bash
   pre-commit install
   pre-commit install --hook-type commit-msg
   ```
4. (Optional) Run every hook against the entire repository to validate your environment:
   ```bash
   pre-commit run --all-files
   ```

## Running the fast PowerShell check-one hook manually

The `.pre-commit-config.yaml` file wires a custom hook that routes staged PowerShell and Python files through `tools/hooks/Invoke-CheckOne.ps1`. You can exercise the same logic on demand to debug a failure:

```bash
pwsh -NoProfile -File tools/hooks/Invoke-CheckOne.ps1 path/to/file.ps1 path/to/file.py
```

The script enforces:
- `python -m py_compile` on Python sources.
- `Invoke-ScriptAnalyzer` (errors only) on PowerShell scripts.

Any failures exit with a non-zero status so the commit is blocked. Install the [PSScriptAnalyzer](https://github.com/PowerShell/PSScriptAnalyzer) module to make sure PowerShell files are analyzed locally.

## Skipping a hook

If you hit an emergency, you can bypass pre-commit as a last resort:

```bash
SKIP=pwsh-check-one pre-commit run --all-files
git commit --no-verify
```

Only use these options temporarily—the CI pipeline runs the same hooks via `pre-commit run --all-files`, so the problem will surface again during validation.
