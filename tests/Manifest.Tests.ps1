Set-StrictMode -Version Latest

Describe 'Repository manifest' {
  It 'lists key guardrail assets' {
    $manifestPath = 'docs/manifest.json'
    Test-Path $manifestPath | Should -BeTrue
    $json = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
    $json.files | Should -Contain '.merge-policy.yaml'
    $json.files | Should -Contain '.mcp/mcp_servers.json'
    $json.files | Should -Contain 'docs/ai/guardrails.md'
  }
}
