Set-StrictMode -Version Latest

Describe 'Invoke-AIToolGuard' {
  It 'requires ChangePlan validation before execution' {
    $script = Get-Content -LiteralPath 'tools/Invoke-AIToolGuard.ps1' -Raw
    $script | Should -Match 'Validate-ChangePlan.ps1'
  }

  It 'runs SafePatch unless skipped' {
    $script = Get-Content -LiteralPath 'tools/Invoke-AIToolGuard.ps1' -Raw
    $script | Should -Match 'SafePatch.ps1'
    $script | Should -Match 'SkipSafePatch'
  }
}
