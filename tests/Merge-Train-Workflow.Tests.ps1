Set-StrictMode -Version Latest

Describe 'Merge Train workflow' {
  It 'defines merge-train GitHub workflow with rerere cache restore and PreFlight check' {
    $path = '.github/workflows/merge-train.yml'
    Test-Path $path | Should -BeTrue
    $content = Get-Content -LiteralPath $path -Raw
    $content | Should -Match 'actions/cache'
    $content | Should -Match 'scripts/PreFlight-Check.ps1'
    $content | Should -Match 'scripts/AutoMerge-Workstream.ps1'
    $content | Should -Match 'rerere'
  }
}
