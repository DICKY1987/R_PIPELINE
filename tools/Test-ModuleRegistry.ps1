Set-StrictMode -Version Latest

function Test-ModuleRegistry {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path,

    [Parameter()]
    [string]$MermaidOutputPath
  )

  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
    throw "Registry file not found at '$Path'."
  }

  $reasons = [System.Collections.Generic.List[string]]::new()
  $rawContent = Get-Content -LiteralPath $Path -Raw -Encoding utf8
  try {
    $document = ConvertFrom-Yaml -Yaml $rawContent -ErrorAction Stop
  } catch {
    $reasons.Add("Registry YAML could not be parsed: $($_.Exception.Message)") | Out-Null
    return [PSCustomObject]@{
      Pass     = $false
      Reasons  = $reasons.ToArray()
      Modules  = @()
      Mermaid  = $null
    }
  }

  if (-not ($document -is [hashtable])) {
    $reasons.Add('Registry root must be a mapping with a ''modules'' entry.') | Out-Null
    return [PSCustomObject]@{
      Pass     = $false
      Reasons  = $reasons.ToArray()
      Modules  = @()
      Mermaid  = $null
    }
  }

  if (-not ($document.ContainsKey('modules'))) {
    $reasons.Add('Registry must define a top-level ''modules'' collection.') | Out-Null
    return [PSCustomObject]@{
      Pass     = $false
      Reasons  = $reasons.ToArray()
      Modules  = @()
      Mermaid  = $null
    }
  }

  $modules = $document['modules']
  if (-not ($modules -is [System.Collections.IEnumerable])) {
    $reasons.Add('Registry ''modules'' entry must be a sequence.') | Out-Null
    return [PSCustomObject]@{
      Pass     = $false
      Reasons  = $reasons.ToArray()
      Modules  = @()
      Mermaid  = $null
    }
  }

  $idsSeen = [System.Collections.Generic.HashSet[string]]::new()
  $namesSeen = [System.Collections.Generic.HashSet[string]]::new()
  $moduleTable = @()

  foreach ($entry in $modules) {
    if (-not ($entry -is [hashtable])) {
      $reasons.Add('Each module entry must be a mapping.') | Out-Null
      continue
    }

    $requiredFields = @('id', 'name', 'version', 'owner', 'dependencies')
    foreach ($field in $requiredFields) {
      if (-not ($entry.ContainsKey($field))) {
        $reasons.Add("Module '{0}' is missing required field '{1}'." -f ($entry['name'] ?? '<unknown>'), $field) | Out-Null
      }
    }

    if (-not $entry.ContainsKey('name')) {
      # Cannot continue validation without a name reference.
      $entry['name'] = '<unknown>'
    }

    $name = [string]$entry['name']
    $id = $entry['id']
    if ($null -ne $id) { $id = [string]$id }

    if ($null -eq $id -or -not ($id -match '^[A-Z]{2}-[A-Z0-9]{3}$')) {
      $reasons.Add("Module '{0}' must have a Two-ID formatted id (AA-123)." -f $name) | Out-Null
    } elseif (-not $idsSeen.Add($id)) {
      $reasons.Add("Module id '$id' is duplicated.") | Out-Null
    }

    if ([string]::IsNullOrWhiteSpace($name)) {
      $reasons.Add('Module name must be a non-empty string.') | Out-Null
    } elseif (-not $namesSeen.Add($name)) {
      $reasons.Add("Module name '$name' is duplicated.") | Out-Null
    }

    $version = $entry['version']
    if ($null -ne $version) { $version = [string]$version }
    if ($null -eq $version -or -not ($version -match '^[0-9]+\.[0-9]+\.[0-9]+$')) {
      $reasons.Add("Module '{0}' version must follow SemVer (MAJOR.MINOR.PATCH)." -f $name) | Out-Null
    }

    if ($entry.ContainsKey('dependencies')) {
      $deps = $entry['dependencies']
      if ($null -eq $deps) {
        $entry['dependencies'] = @()
      } elseif ($deps -is [string]) {
        $reasons.Add("Module '{0}' dependencies must be an array." -f $name) | Out-Null
        $entry['dependencies'] = @()
      } elseif (-not ($deps -is [System.Collections.IEnumerable])) {
        $reasons.Add("Module '{0}' dependencies must be an array." -f $name) | Out-Null
        $entry['dependencies'] = @()
      } else {
        $entry['dependencies'] = @($deps | ForEach-Object { [string]$_ })
      }
    }

    $owner = $entry['owner']
    if ($null -ne $owner) { $owner = [string]$owner }
    if ([string]::IsNullOrWhiteSpace($owner)) {
      $reasons.Add("Module '{0}' owner must be a non-empty string." -f $name) | Out-Null
    }

    $moduleTable += [PSCustomObject]@{
      Name         = $name
      Id           = $id
      Version      = $version
      Owner        = $owner
      Dependencies = @($entry['dependencies'])
    }
  }

  $nameToNodeId = @{}
  foreach ($module in $moduleTable) {
    $nodeId = ($module.Name -replace '[^A-Za-z0-9]', '_')
    $nameToNodeId[$module.Name] = $nodeId
  }

  foreach ($module in $moduleTable) {
    foreach ($dependency in $module.Dependencies) {
      if (-not $nameToNodeId.ContainsKey($dependency)) {
        $reasons.Add("Module '{0}' declares dependency '{1}' that is not present in the registry." -f $module.Name, $dependency) | Out-Null
      }
    }
  }

  $mermaidBuilder = [System.Collections.Generic.List[string]]::new()
  if ($moduleTable.Count -gt 0) {
    $mermaidBuilder.Add('graph LR') | Out-Null
    foreach ($module in $moduleTable | Sort-Object Name) {
      $nodeId = $nameToNodeId[$module.Name]
      $label = "{0} ({1})" -f $module.Name, $module.Id
      $mermaidBuilder.Add("  $nodeId[\"$label\"]") | Out-Null
      foreach ($dependency in $module.Dependencies) {
        $targetId = $nameToNodeId[$dependency]
        if ($null -ne $targetId) {
          $mermaidBuilder.Add("  $nodeId --> $targetId") | Out-Null
        }
      }
    }
  }

  $pass = $reasons.Count -eq 0
  $mermaid = $null
  if ($pass -and $mermaidBuilder.Count -gt 0) {
    $mermaid = ($mermaidBuilder -join [Environment]::NewLine)
    if ($MermaidOutputPath) {
      $directory = Split-Path -Path $MermaidOutputPath -Parent
      if ($directory -and -not (Test-Path -LiteralPath $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
      }
      Set-Content -LiteralPath $MermaidOutputPath -Encoding utf8 -Value $mermaid
    }
  }

  return [PSCustomObject]@{
    Pass     = $pass
    Reasons  = $reasons.ToArray()
    Modules  = $moduleTable
    Mermaid  = $mermaid
  }
}
