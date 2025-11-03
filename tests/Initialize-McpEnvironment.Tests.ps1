Set-StrictMode -Version Latest

Describe 'Initialize-McpEnvironment script' {
  It 'exists and loads MCP configuration files' {
    $scriptPath = 'scripts/Initialize-McpEnvironment.ps1'
    Test-Path $scriptPath | Should -BeTrue
    $content = Get-Content -LiteralPath $scriptPath -Raw
    $content | Should -Match '\.mcp/mcp_servers.json'
    $content | Should -Match '\.mcp/access_groups.json'
  }
}
