Set-StrictMode -Version Latest
Describe 'Repository Sanity' {
  It 'guardrails scaffolding exists' {
    Test-Path 'docs/STYLEGUIDE.md' | Should -BeTrue
    Test-Path 'tools/Verify.ps1'   | Should -BeTrue
  }
}

