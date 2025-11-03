# MCP overview

The Model Control Plane (MCP) centralizes SafePatch tooling.

1. Initialize the environment with `scripts/Initialize-McpEnvironment.ps1`.
2. Inspect `.mcp/mcp_servers.json` for available tool commands.
3. Access roles and privileges through `.mcp/access_groups.json`.
4. Wrapper scripts (`tools/Invoke-AIToolGuard.ps1`) enforce ChangePlan validation prior to invoking MCP servers.

See `docs/SAFE_PATCH_RULES.md` for the required validation pipeline.
