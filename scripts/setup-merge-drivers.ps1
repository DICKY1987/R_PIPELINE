Set-StrictMode -Version Latest

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter()][ValidateSet('global', 'local')][string]$ConfigScope = 'global',
    [Parameter()][switch]$ForceFallback
)

function Get-GitScopeArgument {
    switch ($ConfigScope) {
        'local' { return '--local' }
        default { return '--global' }
    }
}

function Get-ToolPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$CommandName,
        [Parameter()][string[]]$CandidatePaths
    )

    $command = Get-Command -Name $CommandName -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }

    foreach ($candidate in $CandidatePaths) {
        if (-not $candidate) {
            continue
        }

        if (Test-Path -LiteralPath $candidate) {
            try {
                return (Resolve-Path -LiteralPath $candidate -ErrorAction Stop).Path
            } catch {
                continue
            }
        }
    }

    return $null
}

function Set-PersistentGitConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Key,
        [Parameter(Mandatory)][string]$Value
    )

    $scopeArg = Get-GitScopeArgument
    $current = & git config $scopeArg --get $Key 2>$null
    if ($current -eq $Value) {
        return
    }

    if ($PSCmdlet.ShouldProcess("git config $scopeArg $Key", "set to '$Value'")) {
        & git config $scopeArg $Key $Value | Out-Null
    }
}

function Register-StructuredMergeDriver {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter()][string]$ToolPath,
        [Parameter(Mandatory)][string]$StructuredCommandTemplate,
        [Parameter(Mandatory)][string]$FallbackCommand
    )

    $usingStructured = -not $ForceFallback.IsPresent -and $ToolPath
    if ($usingStructured) {
        $command = [string]::Format($StructuredCommandTemplate, $ToolPath)
        Write-Verbose "Configured $Name merge driver using $ToolPath."
    } else {
        $command = $FallbackCommand
        $toolDisplay = if ($ToolPath) { $ToolPath } else { 'not found' }
        Write-Verbose "Using fallback merge driver for $Name (tool $toolDisplay)."
    }

    Set-PersistentGitConfig -Key "merge.$Name.name" -Value "$Name structured merge"
    Set-PersistentGitConfig -Key "merge.$Name.driver" -Value $command
    Set-PersistentGitConfig -Key "merge.$Name.recursive" -Value 'text'
}

Set-PersistentGitConfig -Key 'rerere.enabled' -Value 'true'
Set-PersistentGitConfig -Key 'rerere.autoupdate' -Value 'true'

$jqCandidates = @(
    '/usr/bin/jq',
    '/usr/local/bin/jq',
    '/opt/homebrew/bin/jq'
)

if ($env:ProgramFiles) {
    $jqCandidates += @(
        (Join-Path -Path $env:ProgramFiles -ChildPath 'Git\usr\bin\jq.exe'),
        (Join-Path -Path $env:ProgramFiles -ChildPath 'PowerShell\7\jq.exe')
    )
}

if ($env:ChocolateyInstall) {
    $jqCandidates += (Join-Path -Path $env:ChocolateyInstall -ChildPath 'bin\jq.exe')
}

$yqCandidates = @(
    '/usr/bin/yq',
    '/usr/local/bin/yq',
    '/opt/homebrew/bin/yq'
)

if ($env:ProgramFiles) {
    $yqCandidates += @(
        (Join-Path -Path $env:ProgramFiles -ChildPath 'Git\usr\bin\yq.exe'),
        (Join-Path -Path $env:ProgramFiles -ChildPath 'PowerShell\7\yq.exe')
    )
}

if ($env:ChocolateyInstall) {
    $yqCandidates += (Join-Path -Path $env:ChocolateyInstall -ChildPath 'bin\yq.exe')
}

$jqPath = if ($ForceFallback) { $null } else { Get-ToolPath -CommandName 'jq' -CandidatePaths $jqCandidates }
$yqPath = if ($ForceFallback) { $null } else { Get-ToolPath -CommandName 'yq' -CandidatePaths $yqCandidates }

$jsonStructuredTemplate = @'
"{0}" --null-input --slurpfile base %O --slurpfile ours %A --slurpfile theirs %B "def fold(inputs): reduce inputs[] as $item ({{}}; . * $item); fold([$base[0], $ours[0], $theirs[0]])"
'@

$yamlStructuredTemplate = @'
"{0}" eval-all "select(fileIndex == 0) * select(fileIndex == 1) * select(fileIndex == 2)" %O %A %B
'@

$fallbackCommand = 'git merge-file -L current -L base -L other %A %O %B'

Register-StructuredMergeDriver -Name 'json-structured' -ToolPath $jqPath -StructuredCommandTemplate $jsonStructuredTemplate -FallbackCommand $fallbackCommand
Register-StructuredMergeDriver -Name 'yaml-structured' -ToolPath $yqPath -StructuredCommandTemplate $yamlStructuredTemplate -FallbackCommand $fallbackCommand

Write-Verbose 'Merge driver configuration complete.'
