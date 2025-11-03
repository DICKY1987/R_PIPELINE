Set-StrictMode -Version Latest

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$ToolName,
    [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$BranchName,
    [Parameter()][ValidateNotNullOrEmpty()][string]$WorktreeRoot = '.worktrees'
)

function New-WorktreePath {
    [CmdletBinding()]
    param(
        [string]$Root,
        [string]$Tool
    )

    return Join-Path -Path $Root -ChildPath $Tool
}

function Assert-SafePatchPreconditions {
    [CmdletBinding()]
    param(
        [string]$Path
    )

    if (-not (Test-Path 'tools/SafePatch.ps1')) {
        throw 'SafePatch tooling not found. Run scripts/Initialize-McpEnvironment.ps1 first.'
    }

    $manifest = 'docs/SAFE_PATCH_RULES.md'
    if (-not (Test-Path $manifest)) {
        throw 'SAFE_PATCH_RULES.md missing; cannot guarantee guardrails.'
    }

    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

$targetPath = New-WorktreePath -Root $WorktreeRoot -Tool $ToolName
Assert-SafePatchPreconditions -Path $WorktreeRoot

if ($PSCmdlet.ShouldProcess($targetPath, 'create worktree')) {
    if (-not (Test-Path $targetPath)) {
        git worktree add $targetPath $BranchName | Out-Null
    }

    $metadata = [ordered]@{
        tool      = $ToolName
        branch    = $BranchName
        createdAt = (Get-Date).ToString('o')
    } | ConvertTo-Json -Depth 3

    $metadataPath = Join-Path -Path $targetPath -ChildPath '.tool-worktree.json'
    Set-Content -Path $metadataPath -Value $metadata -Encoding utf8
}
