Set-StrictMode -Version Latest

[CmdletBinding()]
param()

function Set-PersistentGitConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Key,
        [Parameter(Mandatory)][string]$Value
    )

    $current = git config --global --get $Key 2>$null
    if ($current -ne $Value) {
        git config --global $Key $Value | Out-Null
    }
}

function Get-JqPath {
    [CmdletBinding()]
    param()

    $command = Get-Command jq -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }

    $possible = @(
        "$env:ProgramFiles\\Git\\usr\\bin\\jq.exe",
        "$env:ChocolateyInstall\\bin\\jq.exe"
    ) | Where-Object { $_ -and (Test-Path $_) }

    return $possible | Select-Object -First 1
}

function Get-YqPath {
    [CmdletBinding()]
    param()

    $command = Get-Command yq -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }

    $possible = @(
        "$env:ProgramFiles\\Git\\usr\\bin\\yq.exe",
        "$env:ChocolateyInstall\\bin\\yq.exe"
    ) | Where-Object { $_ -and (Test-Path $_) }

    return $possible | Select-Object -First 1
}

function Register-StructuredMergeDriver {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Command,
        [Parameter()][string]$Recursive = 'binary'
    )

    Set-PersistentGitConfig -Key "merge.$Name.name" -Value "$Name structured merge"
    Set-PersistentGitConfig -Key "merge.$Name.driver" -Value $Command
    Set-PersistentGitConfig -Key "merge.$Name.recursive" -Value $Recursive
}

Set-PersistentGitConfig -Key 'rerere.enabled' -Value 'true'
Set-PersistentGitConfig -Key 'rerere.autoupdate' -Value 'true'

$jqPath = Get-JqPath
$yqPath = Get-YqPath

if ($jqPath) {
    $jsonCommand = "\"$jqPath\" -n --slurpfile base %O --slurpfile current %A --slurpfile other %B 'def merge(a;b): reduce b[] as \$item (a; . * \$item); merge(.; [\$base, \$current, \$other])'"
    Register-StructuredMergeDriver -Name 'json-structured' -Command $jsonCommand -Recursive 'binary'
} else {
    Write-Verbose 'jq not available; JSON files will use default merge.'
}

if ($yqPath) {
    $yamlCommand = "\"$yqPath\" eval-all 'select(fileIndex == 0) * select(fileIndex == 1)' %O %A %B"
    Register-StructuredMergeDriver -Name 'yaml-structured' -Command $yamlCommand -Recursive 'binary'
} else {
    Write-Verbose 'yq not available; YAML files will use default merge.'
}

Write-Verbose 'Merge driver configuration complete.'
