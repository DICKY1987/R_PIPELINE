# Worktree orchestration

Use `scripts/New-ToolWorktree.ps1` to create isolated worktrees for AI-assisted tooling.

```powershell
pwsh -File scripts/New-ToolWorktree.ps1 -ToolName claude -BranchName feature/claude-sweep
```

The script ensures SafePatch guardrails by verifying `tools/SafePatch.ps1` and seeding metadata under `.worktrees/<tool>/.tool-worktree.json`.

Before edits, agents must generate ChangePlans validated via `scripts/Validate-ChangePlan.ps1`.
