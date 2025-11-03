Set-StrictMode -Version Latest

Describe 'New-ToolWorktree script' {
  It 'exists and declares CmdletBinding with SupportsShouldProcess' {
    $path = 'scripts/New-ToolWorktree.ps1'
    Test-Path $path | Should -BeTrue
    $content = Get-Content -LiteralPath $path -Raw
    $content | Should -Match '\[CmdletBinding\(SupportsShouldProcess = \$true\)\]'
  }

  It 'documents SafePatch guardrails in the script comments' {
    $content = Get-Content -LiteralPath 'scripts/New-ToolWorktree.ps1' -Raw
    $content | Should -Match 'SafePatch'
  }
}
