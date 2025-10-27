#!/usr/bin/env pwsh
<#
watcher/build.ps1
Hardened PowerShell build entrypoint that routes by extension (.py/.ps1), runs checks, calls py_check.py, runs PSScriptAnalyzer if available, integrates with SPEC-1 validation if present, writes .runs/watch/<timestamp>.json and .jsonl and appends to watcher/watch.log.
This version attempts to run ruff and pyright for Python files (best-effort) and Invoke-ScriptAnalyzer for PowerShell files (best-effort). Failures in optional tools are captured in the JSON output and do not fail the overall script.
#>
param(
  [string[]]$Files,
  [string]$Path = ".",
  [string]$Action = "check",
  [string]$OutputDir = ".runs/watch",
  [switch]$EnableSafePatch,
  [ValidateNotNullOrEmpty()][string]$SafePatchPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
$repoRoot = (Resolve-Path (Join-Path $scriptRoot '..')).Path
$timestamp = (Get-Date).ToString("yyyyMMddTHHmmss")
$OutputPath = Join-Path $OutputDir ($timestamp + ".json")
New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $repoRoot '.runs/cache') -Force | Out-Null

function Log-Line {
  param($Message)
  $logFile = Join-Path $scriptRoot "watch.log"
  $line = "{0} {1}" -f (Get-Date -Format "o"), $Message
  $line | Out-File -FilePath $logFile -Encoding utf8 -Append
}

# Load config if present
$configFile = Join-Path $scriptRoot "watcher/watch.config.json"
$config = $null
if (Test-Path $configFile) {
  try { $config = Get-Content $configFile -Raw | ConvertFrom-Json } catch { $config = $null }
}

if (-not $Files -or $Files.Count -eq 0) {
  $include = @("**/*.py","**/*.ps1")
  if ($config -and $config.include) { $include = $config.include }
  $Files = @()
  foreach ($pat in $include) {
    $Files += (Get-ChildItem -Path $Path -Recurse -File -Include $pat -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName })
  }
  $Files = $Files | Select-Object -Unique
}

$results = @()

function Get-StringHash {
  param([string]$s)
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($s)
  $sha = [System.Security.Cryptography.SHA256]::Create()
  try { ($sha.ComputeHash($bytes) | ForEach-Object { $_.ToString('x2') }) -join '' } finally { $sha.Dispose() }
}

function Get-FileContentHash {
  param([string]$filePath)
  try { (Get-FileHash -Algorithm SHA256 -LiteralPath $filePath).Hash.ToLowerInvariant() } catch { '' }
}

function Get-CachePathForFile {
  param([string]$filePath)
  $key = Get-StringHash -s $filePath
  return (Join-Path (Join-Path $repoRoot '.runs/cache') ("path-" + $key + ".json"))
}

function Try-Run-External {
  param(
    [string]$CmdName,
    [string[]]$Args
  )
  try {
    $out = & $CmdName @Args 2>&1
    return @{ ok = $true; output = ($out -join "`n") }
  } catch {
    return @{ ok = $false; error = $_.Exception.Message }
  }
}

foreach ($file in $Files) {
  try {
    $steps = @()
    $swTotal = [System.Diagnostics.Stopwatch]::StartNew()

    $ext = [IO.Path]::GetExtension($file).ToLowerInvariant()
    $result = [ordered]@{
      file = $file
      handler = $null
      status = "unknown"
      details = @{}
      timestamp = (Get-Date).ToString("o")
      steps = @()
      success = $false
    }

    # Incremental cache check
    $cachePath = Get-CachePathForFile -filePath $file
    $currentHash = Get-FileContentHash -filePath $file
    $swCache = [System.Diagnostics.Stopwatch]::StartNew()
    $cacheHit = $false
    if (Test-Path $cachePath -PathType Leaf -ErrorAction SilentlyContinue) {
      try {
        $prev = Get-Content -LiteralPath $cachePath -Raw | ConvertFrom-Json
        if ($prev -and $prev.hash -eq $currentHash) { $cacheHit = $true }
      } catch { }
    }
    $swCache.Stop()
    $steps += [ordered]@{ name = 'cache-check'; elapsed_ms = [int]$swCache.Elapsed.TotalMilliseconds; success = $true }

    if ($cacheHit) {
      $result.handler = "cache"
      $result.status = "skipped"
      $result.details.cache = @{ hit = $true; hash = $currentHash }
      $result.steps = $steps
      $result.success = $true
      $results += $result
      Log-Line ("CHECK OK (skipped): {0}" -f $file)
      continue
    }

    switch ($ext) {
      ".py" {
        $result.handler = "python-syntax-check"
        $pyHelper = Join-Path $scriptRoot "py_check.py"
        if (Test-Path $pyHelper) {
          try {
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            $proc = & python $pyHelper --file $file 2>&1
            $json = $proc | Out-String
            try {
              $parsed = $json | ConvertFrom-Json -ErrorAction Stop
              $result.status = $parsed.status
              $result.details.py_check = $parsed
            } catch {
              $result.status = "error"
              $result.details.py_check = @{ error = "py_check.py invalid output"; raw = $json }
            }
            $sw.Stop()
            $steps += [ordered]@{ name = 'py_check'; elapsed_ms = [int]$sw.Elapsed.TotalMilliseconds; success = ($result.status -eq 'ok') }
          } catch {
            $result.status = "error"
            $result.details.py_check = @{ error = $_.Exception.Message }
            $steps += [ordered]@{ name = 'py_check'; elapsed_ms = 0; success = $false }
          }
        } else {
          # fallback: attempt compile
          try {
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            python -m py_compile $file 2>&1 | Out-Null
            $result.status = "ok"
            $sw.Stop()
            $steps += [ordered]@{ name = 'py_compile'; elapsed_ms = [int]$sw.Elapsed.TotalMilliseconds; success = $true }
          } catch {
            $result.status = "error"
            $result.details.py_check = @{ error = $_.Exception.Message }
            $steps += [ordered]@{ name = 'py_compile'; elapsed_ms = 0; success = $false }
          }
        }

        # Best-effort: run ruff (if installed)
        if (Get-Command ruff -ErrorAction SilentlyContinue) {
          $sw = [System.Diagnostics.Stopwatch]::StartNew()
          $ruffRes = Try-Run-External -CmdName ruff -Args @("check","--format","json",$file)
          $result.details.ruff = $ruffRes
          # attempt to parse ruff JSON if ok
          if ($ruffRes.ok -and $ruffRes.output) {
            try { $result.details.ruff_parsed = $ruffRes.output | ConvertFrom-Json -ErrorAction Stop } catch { $result.details.ruff_parse_error = $ruffRes.output }
          }
          $sw.Stop()
          $steps += [ordered]@{ name = 'ruff'; elapsed_ms = [int]$sw.Elapsed.TotalMilliseconds; success = $ruffRes.ok }
        } else {
          $result.details.ruff = @{ available = $false }
        }

        # Best-effort: run pyright (if installed)
        if (Get-Command pyright -ErrorAction SilentlyContinue) {
          $sw = [System.Diagnostics.Stopwatch]::StartNew()
          $pyrightRes = Try-Run-External -CmdName pyright -Args @("--outputjson",$file)
          $result.details.pyright = $pyrightRes
          if ($pyrightRes.ok -and $pyrightRes.output) {
            try { $result.details.pyright_parsed = $pyrightRes.output | ConvertFrom-Json -ErrorAction Stop } catch { $result.details.pyright_parse_error = $pyrightRes.output }
          }
          $sw.Stop()
          $steps += [ordered]@{ name = 'pyright'; elapsed_ms = [int]$sw.Elapsed.TotalMilliseconds; success = $pyrightRes.ok }
        } else {
          $result.details.pyright = @{ available = $false }
        }
      }

      ".ps1" {
        $result.handler = "powershell-parse"
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $tokens = $null
        $errors = $null
        [System.Management.Automation.Language.Parser]::ParseFile($file,[ref]$tokens,[ref]$errors) | Out-Null
        if ($errors -and $errors.Count -gt 0) {
          $result.status = "error"
          $result.details.parseErrors = $errors | ForEach-Object { $_.ToString() }
        } else {
          $result.status = "ok"
          $result.details.parseErrors = @()

          if (Get-Command Invoke-ScriptAnalyzer -ErrorAction SilentlyContinue) {
            try {
              $pa = Invoke-ScriptAnalyzer -Path $file -Recurse -Severity "Error","Warning" -ErrorAction SilentlyContinue
              $result.details.PSScriptAnalyzer = ($pa | Select-Object RuleName, Severity, ScriptName | ConvertTo-Json -Depth 3)
            } catch {
              $result.details.PSScriptAnalyzer = @{ ok = $false; error = $_.Exception.Message }
            }
          } else {
            $result.details.PSScriptAnalyzer = @{ available = $false }
          }
        }
        $sw.Stop()
        $steps += [ordered]@{ name = 'ps_parse'; elapsed_ms = [int]$sw.Elapsed.TotalMilliseconds; success = ($result.status -eq 'ok') }
      }

      default {
        $result.handler = "none"
        $result.status = "skipped"
        $result.details = @{ reason = "no handler for extension $ext" }
      }
    }

    # Optional SafePatch adapter (fail-soft)
    if ($EnableSafePatch.IsPresent) {
      $swSP = [System.Diagnostics.Stopwatch]::StartNew()
      $spOk = $false
      $spDetails = @{ ok = $false; issues = @(); raw = $null }
      try {
        $tool = $null
        if ($PSBoundParameters.ContainsKey('SafePatchPath') -and $SafePatchPath -and (Test-Path -LiteralPath $SafePatchPath)) {
          $tool = $SafePatchPath
        } else {
          $specTool = Join-Path $scriptRoot 'SPEC-1-AI-Upkeep-Suite-v2-Guardrails-MCP/scripts/validation/Invoke-SafePatchValidation.ps1'
          if (Test-Path -LiteralPath $specTool) { $tool = $specTool }
        }

        if ($tool) {
          $isPs1 = ([IO.Path]::GetExtension($tool)).ToLowerInvariant() -eq '.ps1'
          if ($isPs1) {
            $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $tool -Path $file 2>&1
          } else {
            $out = & $tool $file 2>&1
          }
          $txt = ($out -join "`n")
          # Try JSON first
          $parsed = $null
          try { $parsed = $txt | ConvertFrom-Json -ErrorAction Stop } catch { $parsed = $null }
          if ($parsed -ne $null) {
            $spDetails.raw = $txt
            if ($parsed.PSObject.Properties.Name -contains 'ok') { $spDetails.ok = [bool]$parsed.ok }
            if ($parsed.PSObject.Properties.Name -contains 'issues') { $spDetails.issues = @($parsed.issues) }
            $spOk = $true
          } else {
            # Try XML parse best-effort
            try {
              [xml]$xml = $txt
              $spDetails.raw = $txt
              # Minimal mapping: treat any <issue> nodes as issues entries
              $issueNodes = @()
              if ($xml -and $xml.SelectNodes('//issue')) { $issueNodes = $xml.SelectNodes('//issue') }
              $spDetails.issues = @($issueNodes | ForEach-Object { $_.OuterXml })
              $spDetails.ok = $true
              $spOk = $true
            } catch {
              $spDetails.raw = $txt
            }
          }
        } else {
          $spDetails = @{ ok = $false; issues = @(); raw = 'SafePatch tool not found' }
        }
      } catch {
        $spDetails = @{ ok = $false; issues = @(); raw = $_.Exception.Message }
      }
      $swSP.Stop()
      $result.details.SafePatch = $spDetails
      $steps += [ordered]@{ name = 'safepatch'; elapsed_ms = [int]$swSP.Elapsed.TotalMilliseconds; success = $spOk }
    }

    # SPEC-1 integration (best-effort)
    $specPath = Join-Path $scriptRoot "SPEC-1-AI-Upkeep-Suite-v2-Guardrails-MCP/scripts/validation"
    if (Test-Path $specPath) {
      $specScripts = Get-ChildItem -Path $specPath -Filter "*.ps1" -File -ErrorAction SilentlyContinue
      if ($specScripts -and $specScripts.Count -gt 0) {
        $specResults = @()
        foreach ($s in $specScripts) {
          try {
            $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $s.FullName -ArgumentList $file 2>&1
            $specResults += @{ script = $s.Name; output = ($out -join "`n") }
          } catch {
            $specResults += @{ script = $s.Name; error = $_.Exception.Message }
          }
        }
        $result.details.SPEC1 = $specResults
      }
    }

    # finalize record
    $swTotal.Stop()
    $result.steps = $steps
    $result.success = ($result.status -eq 'ok' -or $result.status -eq 'skipped')

    # update cache with current hash
    try {
      @{ path = $file; hash = $currentHash; when = (Get-Date).ToString('o') } | ConvertTo-Json -Depth 5 | Out-File -FilePath $cachePath -Encoding utf8
    } catch { }

    $results += $result
    Log-Line ("CHECK OK: {0} -> {1}" -f $file, $result.status)
  } catch {
    $err = $_.Exception.Message
    $results += [ordered]@{ file=$file; handler="internal"; status="error"; details=@{message=$err}; timestamp=(Get-Date).ToString("o") }
    Log-Line ("CHECK ERROR: {0} -> {1}" -f $file, $err)
  }
}

# write results JSON as an array deterministically (even for single item)
ConvertTo-Json -Depth 10 -InputObject $results | Out-File -FilePath $OutputPath -Encoding utf8

# Also append each record to .runs/watch/<timestamp>.jsonl
$recordsPath = Join-Path $OutputDir ($timestamp + ".jsonl")
foreach ($r in $results) {
  $r | ConvertTo-Json -Depth 10 | Out-File -FilePath $recordsPath -Encoding utf8 -Append
}

Write-Host "Wrote results to $OutputPath"
exit 0
