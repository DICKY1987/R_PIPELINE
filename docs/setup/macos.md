# macOS setup checklist

- Install Homebrew packages: `brew install git jq yq conftest semgrep gitleaks powershell`.
- Configure git identity and rerere as in Windows checklist.
- Run `pwsh -File scripts/setup-merge-drivers.ps1` to register merge drivers.
- Validate MCP config with `scripts/Initialize-McpEnvironment.ps1`.
- Ensure Terminal can access GitHub CLI with `gh auth login`.
