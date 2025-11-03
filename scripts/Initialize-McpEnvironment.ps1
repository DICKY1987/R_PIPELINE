Set-StrictMode -Version Latest

[CmdletBinding()]
param()

function Get-McpConfig {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path $Path)) {
        throw "MCP configuration file not found: $Path"
    }

    $raw = Get-Content -LiteralPath $Path -Raw
    return $raw | ConvertFrom-Json -ErrorAction Stop
}

$serversPath = '.mcp/mcp_servers.json'
$accessPath = '.mcp/access_groups.json'

$servers = Get-McpConfig -Path $serversPath
$access = Get-McpConfig -Path $accessPath

Write-Verbose "Loaded $($servers.servers.Count) MCP servers"
Write-Verbose "Loaded $($access.groups.Keys.Count) access groups"

foreach ($groupName in $access.groups.Keys) {
    $group = $access.groups[$groupName]
    foreach ($tool in $group.tools) {
        if (-not ($servers.servers.name -contains $tool)) {
            throw "Tool '$tool' referenced by group '$groupName' is not defined in $serversPath."
        }
    }
}

Write-Verbose 'MCP configuration is valid.'
