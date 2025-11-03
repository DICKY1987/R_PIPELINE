# Linux setup checklist

- Configure git identity and rerere:
  ```bash
  git config --global user.name "Your Name"
  git config --global user.email "you@example.com"
  git config --global rerere.enabled true
  git config --global rerere.autoupdate true
  ```
- Install dependencies: jq, yq, conftest, semgrep, gitleaks, Python 3.11, Node.js LTS.
- Ensure `pwsh` (PowerShell 7+) is installed for SafePatch scripts.
- Run `scripts/setup-merge-drivers.ps1` and `scripts/Initialize-McpEnvironment.ps1`.
- Authenticate with GitHub CLI (`gh auth login`).
