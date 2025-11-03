# Windows setup checklist

1. Install Git for Windows and configure:
   ```powershell
   git config --global user.name "Your Name"
   git config --global user.email "you@example.com"
   git config --global rerere.enabled true
   git config --global rerere.autoupdate true
   ```
2. Authenticate GitHub CLI with `gh auth login --scopes repo,workflow`.
3. Set `CLAUDE_CODE_GIT_BASH_PATH` to your Git Bash executable for AI tooling wrappers.
4. Run `scripts/setup-merge-drivers.ps1` to register structured drivers.
5. Execute `scripts/Initialize-McpEnvironment.ps1` to validate MCP configuration.
6. Install PowerShell 7+ and ensure `pwsh` is available in PATH.
