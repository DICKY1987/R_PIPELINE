Set-StrictMode -Version Latest

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$ChangePlan,
    [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$UnifiedDiff,
    [Parameter(Mandatory)][ValidateCount(1, 32)][string[]]$Command,
    [Parameter()][switch]$SkipSafePatch
)

$validator = 'scripts/Validate-ChangePlan.ps1'
if (-not (Test-Path $validator)) {
    throw 'Validation script missing; run Initialize-McpEnvironment first.'
}

& pwsh -NoProfile -File $validator -ChangePlanPath $ChangePlan -UnifiedDiffPath $UnifiedDiff
if ($LASTEXITCODE -ne 0) {
    throw 'ChangePlan validation failed.'
}

if (-not $SkipSafePatch) {
    if (-not (Test-Path 'tools/SafePatch.ps1')) {
        throw 'SafePatch script missing.'
    }

    & pwsh -NoProfile -File 'tools/SafePatch.ps1' -NoPush
    if ($LASTEXITCODE -ne 0) {
        throw 'SafePatch pipeline failed. Resolve issues before invoking AI tools.'
    }
}

if ($PSCmdlet.ShouldProcess(($Command -join ' '), 'invoke AI tool')) {
    & $Command
}
