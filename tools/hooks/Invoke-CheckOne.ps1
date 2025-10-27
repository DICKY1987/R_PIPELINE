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

$missingTools = @()
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    $missingTools += 'python'
}
if ($missingTools.Count -gt 0) {
    throw "Required tools missing for check-one: $($missingTools -join ', ')"
}

$failures = @()
foreach ($target in $resolvedTargets | Sort-Object -Unique) {
    $extension = [IO.Path]::GetExtension($target).ToLowerInvariant()
    switch ($extension) {
        '.py' {
            $output = & python -m py_compile $target 2>&1
            if ($LASTEXITCODE -ne 0) {
                $message = ($output | Out-String).Trim()
                if (-not $message) { $message = 'python -m py_compile reported an unknown failure.' }
                $failures += @{ File = $target; Message = $message }
            }
        }
        '.ps1' {
            $pssa = Get-Command Invoke-ScriptAnalyzer -ErrorAction SilentlyContinue
            if ($pssa) {
                $issues = Invoke-ScriptAnalyzer -Path $target -Severity Error -ErrorAction Stop
                if ($issues.Count -gt 0) {
                    $details = ($issues | ForEach-Object { "[{0}:{1}] {2}" -f $_.ScriptPath, $_.Line, $_.Message }) -join "`n"
                    $failures += @{ File = $target; Message = $details }
                }
            }
        }
    }
}

if ($failures.Count -gt 0) {
    foreach ($failure in $failures) {
        Write-Error ("{0}`n{1}" -f $failure.File, $failure.Message)
    }
    exit 1
}
