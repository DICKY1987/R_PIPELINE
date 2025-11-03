Set-StrictMode -Version Latest

Describe 'Merge governance configuration' {
  It 'provides a merge policy file at repo root with required sections' {
    Test-Path '.merge-policy.yaml' | Should -BeTrue
    $content = Get-Content -LiteralPath '.merge-policy.yaml' -Raw
    $content | Should -Match 'merge-strategies:'
    $content | Should -Match 'verification-gates:'
    $content | Should -Match 'audit-log:'
  }

  It 'sets structured merge drivers in .gitattributes' {
    Test-Path '.gitattributes' | Should -BeTrue
    $content = Get-Content -LiteralPath '.gitattributes' -Raw
    $content | Should -Match 'merge=json-structured'
    $content | Should -Match 'merge=yaml-structured'
  }
}
