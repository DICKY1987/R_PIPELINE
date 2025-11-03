Set-StrictMode -Version Latest

Describe 'ChangePlan validation assets' {
  It 'includes schemas for changeplan and unified diff' {
    Test-Path 'docs/schemas/changeplan.schema.json' | Should -BeTrue
    Test-Path 'docs/schemas/unifieddiff.schema.json' | Should -BeTrue
  }

  It 'has an OPA policy enforcing ChangePlan rules' {
    Test-Path 'docs/policy/changeplan.rego' | Should -BeTrue
  }

  It 'provides a validation script that references the schema and policy' {
    $script = Get-Content -LiteralPath 'scripts/Validate-ChangePlan.ps1' -Raw
    $script | Should -Match 'changeplan.schema.json'
    $script | Should -Match 'unifieddiff.schema.json'
    $script | Should -Match 'changeplan.rego'
  }
}
