# Pester tests for test_sample.ps1
Import-Module Pester -ErrorAction SilentlyContinue

Describe "PowerShell sample file" {
  It "should parse without syntax errors" {
    $file = Join-Path $PSScriptRoot "test_sample.ps1"
    $tokens = $null
    $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($file,[ref]$tokens,[ref]$errors) | Out-Null
    $errors.Count | Should -Be 0
  }

  It "should export Get-SampleValue function" {
    . (Join-Path $PSScriptRoot "test_sample.ps1")
    (Get-Command Get-SampleValue -ErrorAction SilentlyContinue) | Should -Not -BeNullOrEmpty
    $res = Get-SampleValue
    $res.ok | Should -Be $true
  }
}