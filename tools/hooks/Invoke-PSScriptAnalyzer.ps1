#!/usr/bin/env pwsh
[CmdletBinding()]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$TargetPaths
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $TargetPaths -or $TargetPaths.Count -eq 0) {
    return
}

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Resolve-Path (Join-Path $scriptRoot '..' '..')

$resolvedTargets = @()
foreach ($path in $TargetPaths) {
    if ([string]::IsNullOrWhiteSpace($path)) { continue }
    $fullPath = Join-Path $repoRoot $path
    if (Test-Path -LiteralPath $fullPath) {
        $resolvedTargets += (Resolve-Path -LiteralPath $fullPath).Path
    }
}

if ($resolvedTargets.Count -eq 0) {
    return
}

$pssa = Get-Command Invoke-ScriptAnalyzer -ErrorAction SilentlyContinue
if (-not $pssa) {
    throw 'Invoke-ScriptAnalyzer is required for this hook. Install PSScriptAnalyzer to continue.'
}

$issues = Invoke-ScriptAnalyzer -Path $resolvedTargets -Severity Error -ErrorAction Stop
if ($issues.Count -eq 0) {
    return
}

foreach ($issue in $issues) {
    $location = "[{0}:{1}]" -f $issue.ScriptPath, $issue.Line
    $rule = if ($issue.RuleName) { $issue.RuleName } else { 'UnknownRule' }
    Write-Error "$location $rule - $($issue.Message)"
}

exit 1
