Set-StrictMode -Version Latest

Describe 'Branch protection automation' {
  It 'defines CODEOWNERS with critical paths' {
    Test-Path 'CODEOWNERS' | Should -BeTrue
    (Get-Content -LiteralPath 'CODEOWNERS' -Raw) | Should -Match 'docs/merge/'
  }

  It 'ships a configuration script for branch protection' {
    $script = 'scripts/github/Configure-BranchProtection.ps1'
    Test-Path $script | Should -BeTrue
    (Get-Content -LiteralPath $script -Raw) | Should -Match 'gh repo edit'
  }
}
