Set-StrictMode -Version Latest

Describe 'AI guardrail tooling' {
  It 'provides a safety wrapper script for AI tools' {
    $script = 'tools/Invoke-AIToolGuard.ps1'
    Test-Path $script | Should -BeTrue
    $content = Get-Content -LiteralPath $script -Raw
    $content | Should -Match 'ChangePlan'
    $content | Should -Match 'SafePatch'
  }

  It 'includes tests or mocks for the wrapper' {
    Test-Path 'tests/tools/Invoke-AIToolGuard.Tests.ps1' | Should -BeTrue
  }
}
