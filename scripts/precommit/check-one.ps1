Set-StrictMode -Version Latest
[CmdletBinding()]
param(
  [Parameter(ValueFromRemainingArguments=$true)]
  [string[]]$Files
)

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

Write-Information "check-one: evaluating $(@($Files).Count) files"

if (-not $Files -or $Files.Count -eq 0) {
  Write-Information 'check-one: no files passed; exiting 0'
  exit 0
}

$existing = @($Files | Where-Object { Test-Path -LiteralPath $_ })
if ($existing.Count -eq 0) { Write-Information 'check-one: no existing paths'; exit 0 }

$psFiles = @($existing | Where-Object { $_ -match '\.(ps1|psm1)$' })
$pyFiles = @($existing | Where-Object { $_ -match '\.(py)$' })

$hadError = $false

if ($psFiles.Count -gt 0) {
  if (Get-Command Invoke-ScriptAnalyzer -ErrorAction SilentlyContinue) {
    Write-Information "check-one: PSScriptAnalyzer on $($psFiles.Count) file(s)"
    $res = Invoke-ScriptAnalyzer -Path $psFiles -Severity Error
    if ($res) {
      $hadError = $true
      foreach ($r in $res) {
        Write-Error ("PSSA:{0}:{1}:{2} {3}" -f $r.ScriptPath,$r.Line,$r.RuleName,$r.Message)
      }
    }
  } else {
    Write-Information 'check-one: Invoke-ScriptAnalyzer not found; skipping PS analysis'
  }
}

if ($pyFiles.Count -gt 0) {
  if (Get-Command ruff -ErrorAction SilentlyContinue) {
    Write-Information "check-one: ruff on $($pyFiles.Count) file(s)"
    & ruff check --select F,E --exit-zero-even-if-changed --output-format concise -- $pyFiles
    if ($LASTEXITCODE -ne 0) { $hadError = $true }
  } else {
    Write-Information 'check-one: ruff not found; skipping Python analysis'
  }
}

if ($hadError) { exit 1 } else { exit 0 }
