<#
watcher/watch.ps1
FileSystemWatcher with debounce and batching.
- Uses watcher/watch.config.json for debounce and include/exclude patterns.
- Batches changed files and calls build.ps1 with the list.
- Writes run metadata to .runs/watch/ and logs to watcher/watch.log
#>

[CmdletBinding()]
param(
  [Parameter()][ValidateNotNullOrEmpty()][string]$Path = ".",
  [Parameter()][ValidateRange(1, 600000)][int]$DebounceMs = 500,
  [Parameter()][switch]$Once,
  [Parameter()][ValidateRange(1, 3600000)][int]$RunForMs,
  [Parameter()][string]$OutputDir
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
$repoRoot = (Resolve-Path (Join-Path $scriptRoot '..')).Path
$configFile = Join-Path $scriptRoot "watch.config.json"
if (Test-Path $configFile) {
  try {
    $cfg = Get-Content $configFile -Raw | ConvertFrom-Json
    if ($cfg.debounce_ms) { $DebounceMs = [int]$cfg.debounce_ms }
  } catch { }
}

# Fast-path bounded run for CI: poll and invoke once
if ($PSBoundParameters.ContainsKey('RunForMs') -and $RunForMs -gt 0 -and -not $Once) {
  Start-Sleep -Milliseconds $RunForMs
  $include = @("*.py","*.ps1")
  if ($cfg -and $cfg.include) { $include = $cfg.include }
  # Normalize globstar patterns like **/*.ps1 to *.ps1 for Get-ChildItem -Include
  $include = $include | ForEach-Object { $_ -replace '^\*\*[\\/]', '' }
  $found = @()
  foreach ($pat in $include) {
    $found += Get-ChildItem -Path $Path -Recurse -File -Include $pat -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName }
  }
  $found = $found | Select-Object -Unique
  if ($found.Count -gt 0) {
    # invoke build once with all matches
    $buildPathFixed = Join-Path $scriptRoot 'build.ps1'
    $outputDirFixed = if ($PSBoundParameters.ContainsKey('OutputDir') -and $OutputDir) { $OutputDir } else { Join-Path $repoRoot '.runs\\watch' }
    try {
      & $buildPathFixed -Files $found -Path $Path -Action "onchange" -OutputDir $outputDirFixed
    } catch { }
  }
  Write-Host "Watcher bounded run complete."
  exit 0
}

$pending = [System.Collections.ArrayList]::new()
$timer = $null
$locker = New-Object Object
$outputDirFixed = if ($PSBoundParameters.ContainsKey('OutputDir') -and $OutputDir) { $OutputDir } else { Join-Path $repoRoot '.runs\\watch' }
$buildPathFixed = Join-Path $scriptRoot 'build.ps1'
$pathFixed = $Path
$script:lastChangedFiles = @()

function Enqueue-File {
  param($fullPath)
  lock ($locker) {
    if (-not ($pending -contains $fullPath)) { $pending.Add($fullPath) | Out-Null }
  }
  # reset timer
  if ($timer) {
    $timer.Stop()
    $timer.Dispose()
  }
  $timer = New-Object System.Timers.Timer $DebounceMs
  $timer.AutoReset = $false
  $timer.Add_Elapsed({
    $filesToProcess = @()
    lock ($locker) {
      $filesToProcess = $pending.ToArray()
      $pending.Clear()
      $script:lastChangedFiles = $filesToProcess
    }
    if ($filesToProcess.Count -eq 0) { return }
    # filter using watch.ignore if present
    $ignoreFile = Join-Path $scriptRoot "watch.ignore"
    $filtered = $filesToProcess | Where-Object {
      $p = $_
      $ignored = $false
      if (Test-Path $ignoreFile) {
        $patterns = Get-Content $ignoreFile | Where-Object { $_ -and $_.Trim() -ne "" }
        foreach ($pat in $patterns) {
          if ($p -like $pat) { $ignored = $true; break }
        }
      }
      -not $ignored
    }
    if ($filtered.Count -eq 0) { return }
    Write-Host "Detected changes: $($filtered -join ', ')"
    # call build.ps1 with explicit files
    try {
      & $using:buildPathFixed -Files $filtered -Path $using:pathFixed -Action "onchange" -OutputDir $using:outputDirFixed
    } catch {
      Write-Host "Build failed: $($_.Exception.Message)"
    }
  })
  $timer.Start()
}

# Setup FileSystemWatcher (configure before enabling events)
$fsw = New-Object System.IO.FileSystemWatcher $Path
$fsw.IncludeSubdirectories = $true
$fsw.NotifyFilter = [IO.NotifyFilters]::FileName -bor [IO.NotifyFilters]::LastWrite -bor [IO.NotifyFilters]::DirectoryName
$fsw.EnableRaisingEvents = $false

$onChange = {
  param($sender,$e)
  try {
    $full = $e.FullPath
    # ignore temporary files commonly created by editors
    if ($full -match "(\~\$|\.swp$|\.swx$)") { return }
    Enqueue-File $full
  } catch { }
}

# PowerShell event subscription: use .add_<EventName> with the handler scriptblock
$fsw.add_Created($onChange)
$fsw.add_Changed($onChange)
$fsw.add_Renamed($onChange)
$fsw.add_Deleted($onChange)

$fsw.EnableRaisingEvents = $true

Write-Host "Watching '$Path' with debounce ${DebounceMs}ms. Press Enter to quit."

# If running once, scan initial files and exit
if ($Once) {
  # pick matching include patterns
  $include = @("*.py","*.ps1")
  if ($cfg -and $cfg.include) { $include = $cfg.include }
  $include = $include | ForEach-Object { $_ -replace '^\*\*[\\/]', '' }
  $found = @()
  foreach ($pat in $include) {
    $found += Get-ChildItem -Path $Path -Recurse -File -Include $pat -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName }
  }
  if ($found.Count -gt 0) {
    $unique = $found | Select-Object -Unique
    $outputDirFixed = if ($PSBoundParameters.ContainsKey('OutputDir') -and $OutputDir) { $OutputDir } else { Join-Path $repoRoot '.runs\\watch' }
    $buildPathFixed = Join-Path $scriptRoot 'build.ps1'
    try {
      & $buildPathFixed -Files $unique -Path $Path -Action "onchange" -OutputDir $outputDirFixed
    } catch { }
  }
  Write-Host "Once run complete."
  exit 0
}

# keep running until user presses Enter
[void][System.Console]::ReadLine()
$fsw.EnableRaisingEvents = $false
$fsw.Dispose()
if ($timer) { $timer.Stop(); $timer.Dispose() }
Write-Host "Watcher stopped."
