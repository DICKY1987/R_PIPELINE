<#
watcher/watch.ps1
FileSystemWatcher with debounce and batching.
- Uses watcher/watch.config.json for debounce and include/exclude patterns.
- Batches changed files and calls build.ps1 with the list.
- Writes run metadata to .runs/watch/ and logs to watcher/watch.log
#>

param(
  [string]$Path = ".",
  [int]$DebounceMs = 500,
  [switch]$Once
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
$configFile = Join-Path $scriptRoot "watch.config.json"
if (Test-Path $configFile) {
  try {
    $cfg = Get-Content $configFile -Raw | ConvertFrom-Json
    if ($cfg.debounce_ms) { $DebounceMs = [int]$cfg.debounce_ms }
  } catch { }
}

$pending = [System.Collections.ArrayList]::new()
$timer = $null
$locker = New-Object Object

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
    $build = Join-Path $scriptRoot "build.ps1"
    try {
      & $build -Files $filtered -Path $Path -Action "onchange"
    } catch {
      Write-Host "Build failed: $($_.Exception.Message)"
    }
  })
  $timer.Start()
}

# Setup FileSystemWatcher
$fsw = New-Object System.IO.FileSystemWatcher $Path -Property @{
  IncludeSubdirectories = $true
  EnableRaisingEvents = $true
}

$onChange = {
  param($sender,$e)
  try {
    $full = $e.FullPath
    # ignore temporary files commonly created by editors
    if ($full -match "(\~\$|\.swp$|\.swx$)") { return }
    Enqueue-File $full
  } catch { }
}

$fsw.Created += $onChange
$fsw.Changed += $onChange
$fsw.Renamed += $onChange
$fsw.Deleted += $onChange

Write-Host "Watching '$Path' with debounce ${DebounceMs}ms. Press Enter to quit."

# If running once, scan initial files and exit
if ($Once) {
  # pick matching include patterns
  $include = @("*.py","*.ps1")
  if ($cfg -and $cfg.include) { $include = $cfg.include }
  $found = @()
  foreach ($pat in $include) {
    $found += Get-ChildItem -Path $Path -Recurse -File -Include $pat -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName }
  }
  if ($found.Count -gt 0) {
    Enqueue-File ($found | Select-Object -Unique)
    # wait briefly for timer to fire
    Start-Sleep -Milliseconds ($DebounceMs + 200)
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