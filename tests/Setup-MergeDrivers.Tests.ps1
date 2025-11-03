Set-StrictMode -Version Latest

Describe 'setup-merge-drivers script' {
  It 'exists at scripts/setup-merge-drivers.ps1 with strict mode and CmdletBinding' {
    $path = 'scripts/setup-merge-drivers.ps1'
    Test-Path $path | Should -BeTrue
    $content = Get-Content -LiteralPath $path -Raw
    $content | Should -Match 'Set-StrictMode -Version Latest'
    $content | Should -Match '\[CmdletBinding\(\)\]'
  }

  It 'enables rerere in persistent git config' {
    $content = Get-Content -LiteralPath 'scripts/setup-merge-drivers.ps1' -Raw
    $content | Should -Match "'rerere\\.enabled'"
    $content | Should -Match "'rerere\\.autoupdate'"
  }

  It 'configures merge drivers for JSON and YAML using jq and yq with fallbacks' {
    $content = Get-Content -LiteralPath 'scripts/setup-merge-drivers.ps1' -Raw
    $content | Should -Match 'Get-JqPath'
    $content | Should -Match 'Get-YqPath'
    $content | Should -Match 'json-structured'
    $content | Should -Match 'yaml-structured'
  }
}
