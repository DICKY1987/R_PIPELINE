Set-StrictMode -Version Latest

[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$ChangePlanPath,
    [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$UnifiedDiffPath
)

$changePlanSchema = 'docs/schemas/changeplan.schema.json'
$diffSchema = 'docs/schemas/unifieddiff.schema.json'
$opaPolicy = 'docs/policy/changeplan.rego'

if (-not (Test-Path $ChangePlanPath)) {
    throw "ChangePlan file not found: $ChangePlanPath"
}

if (-not (Test-Path $UnifiedDiffPath)) {
    throw "Unified diff file not found: $UnifiedDiffPath"
}

$planContent = Get-Content -LiteralPath $ChangePlanPath -Raw
$diffContent = Get-Content -LiteralPath $UnifiedDiffPath -Raw

if (-not (Test-Path $changePlanSchema)) {
    throw 'ChangePlan schema missing.'
}

if (-not (Test-Path $diffSchema)) {
    throw 'Unified diff schema missing.'
}

if (-not ($planContent | Test-Json -SchemaFile $changePlanSchema)) {
    throw 'ChangePlan does not conform to schema.'
}

if (-not ($diffContent | Test-Json -SchemaFile $diffSchema)) {
    throw 'Unified diff does not conform to schema.'
}

$conftest = Get-Command conftest -ErrorAction SilentlyContinue
if ($conftest) {
    $temp = New-TemporaryFile
    try {
        $input = @{ changeplan = ($planContent | ConvertFrom-Json) } | ConvertTo-Json -Depth 10
        Set-Content -Path $temp -Value $input -Encoding utf8
        & $conftest.Path test $temp --policy (Split-Path -Path $opaPolicy) | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw 'OPA policy validation failed.'
        }
    }
    finally {
        Remove-Item -LiteralPath $temp -ErrorAction SilentlyContinue
    }
} else {
    Write-Warning 'conftest not available; skipping OPA validation.'
}
