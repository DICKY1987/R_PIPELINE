Set-StrictMode -Version Latest

Describe 'Pre-Commit Configuration' {
  It 'has a .pre-commit-config.yaml at repo root' {
    Test-Path '.pre-commit-config.yaml' | Should -BeTrue
  }

  It 'includes Black, Ruff, Commitizen repos and a custom pwsh hook' {
    $cfg = Get-Content -LiteralPath '.pre-commit-config.yaml' -Raw
    $cfg | Should -Match 'psf/black'
    $cfg | Should -Match 'astral-sh/ruff-pre-commit'
    $cfg | Should -Match 'commitizen-tools/commitizen'
    $cfg | Should -Match 'id:\s*pwsh-check-one'
    $cfg | Should -Match 'scripts/precommit/check-one.ps1'
  }

  It 'has the custom hook script with strict mode and CmdletBinding' {
    $hook = 'scripts/precommit/check-one.ps1'
    Test-Path $hook | Should -BeTrue
    $text = Get-Content -LiteralPath $hook -Raw
    $text | Should -Match 'Set-StrictMode -Version Latest'
    $text | Should -Match '\[CmdletBinding\(\)\]'
  }
}

