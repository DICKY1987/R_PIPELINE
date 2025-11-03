# AI guardrails

AI tooling must operate through `tools/Invoke-AIToolGuard.ps1` to enforce the ChangePlan → SafePatch workflow.

## Requirements

- Generate a ChangePlan and unified diff before edits.
- Validate artifacts via `scripts/Validate-ChangePlan.ps1`.
- Run SafePatch pipeline locally using `tools/SafePatch.ps1`.
- Commit only after MCP verification succeeds.

See `docs/workflows/worktrees.md` for worktree setup and `docs/mcp/overview.md` for MCP integration.

The scheduled workflow `.github/workflows/ai-guardrails.yml` performs weekday dry-runs to ensure ChangePlan samples stay valid.
