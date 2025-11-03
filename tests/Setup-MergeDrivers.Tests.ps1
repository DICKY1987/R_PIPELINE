Set-StrictMode -Version Latest

Describe 'setup-merge-drivers script' {
  It 'exists at scripts/setup-merge-drivers.ps1 with strict mode and CmdletBinding' {
    $path = 'scripts/setup-merge-drivers.ps1'
    Test-Path $path | Should -BeTrue
    $content = Get-Content -LiteralPath $path -Raw
    $content | Should -Match 'Set-StrictMode -Version Latest'
    $content | Should -Match '\[CmdletBinding'
  }

  It 'enables rerere in persistent git config' {
    $content = Get-Content -LiteralPath 'scripts/setup-merge-drivers.ps1' -Raw
    $content | Should -Match "'rerere\\.enabled'"
    $content | Should -Match "'rerere\\.autoupdate'"
  }

  It 'configures merge drivers with structured and fallback commands' {
    $content = Get-Content -LiteralPath 'scripts/setup-merge-drivers.ps1' -Raw
    $content | Should -Match 'Register-StructuredMergeDriver'
    $content | Should -Match 'json-structured'
    $content | Should -Match 'yaml-structured'
    $content | Should -Match 'Get-ToolPath'
  }

  It 'supports WhatIf/Confirm semantics for git configuration' {
    $content = Get-Content -LiteralPath 'scripts/setup-merge-drivers.ps1' -Raw
    $content | Should -Match 'SupportsShouldProcess\s*=\s*\$true'
  }

  It 'defines a merge-file fallback for environments without jq/yq' {
    $content = Get-Content -LiteralPath 'scripts/setup-merge-drivers.ps1' -Raw
    $content | Should -Match 'git merge-file'
  }
}
