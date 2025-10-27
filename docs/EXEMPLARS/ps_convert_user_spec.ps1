Set-StrictMode -Version Latest
function Convert-UserSpec {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][ValidateNotNull()] [pscustomobject] $UserSpec
  )
  if (-not $UserSpec.id) { throw 'id required' }
  $id = ("$($UserSpec.id)").Trim()
  $nameValue = if ($UserSpec.PSObject.Properties.Name -contains 'name' -and $null -ne $UserSpec.name) { [string]$UserSpec.name } else { '' }
  $name = $nameValue.Trim()
  [pscustomobject]@{ id = $id; name = (if ($name) { $name } else { 'UNKNOWN' }) }
}

# Pester v5
Describe 'Convert-UserSpec' {
  It 'normalizes name' {
    $out = Convert-UserSpec -UserSpec ([pscustomobject]@{id='42';name=' Ada '})
    $out.name | Should -Be 'Ada'
  }
  It 'throws on missing id' {
    { Convert-UserSpec -UserSpec ([pscustomobject]@{name='Ada'}) } | Should -Throw
  }
}

