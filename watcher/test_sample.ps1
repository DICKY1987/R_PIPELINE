# Sample PowerShell file used for Pester tests
function Get-SampleValue {
  param()
  return @{ ok = $true; ts = (Get-Date).ToString("o") }
}