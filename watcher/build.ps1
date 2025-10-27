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
  [string]$OutputDir = ".runs/watch"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
$timestamp = (Get-Date).ToString("yyyyMMddTHHmmss")
$OutputPath = Join-Path $OutputDir ($timestamp + ".json")
New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null

function Log-Line {
  param($Message)
  $logFile = Join-Path $scriptRoot "watcher/watch.log"
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
    $ext = [IO.Path]::GetExtension($file).ToLowerInvariant()
    $result = [ordered]@{
      file = $file
      handler = $null
      status = "unknown"
      details = @{}
      timestamp = (Get-Date).ToString("o")
    }

    switch ($ext) {
      ".py" {
        $result.handler = "python-syntax-check"
        $pyHelper = Join-Path $scriptRoot "watcher/py_check.py"
        if (Test-Path $pyHelper) {
          try {
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
          } catch {
            $result.status = "error"
            $result.details.py_check = @{ error = $_.Exception.Message }
          }
        } else {
          # fallback: attempt compile
          try {
            python -m py_compile $file 2>&1 | Out-Null
            $result.status = "ok"
          } catch {
            $result.status = "error"
            $result.details.py_check = @{ error = $_.Exception.Message }
          }
        }

        # Best-effort: run ruff (if installed)
        if (Get-Command ruff -ErrorAction SilentlyContinue) {
          $ruffRes = Try-Run-External -CmdName ruff -Args @("check","--format","json",$file)
          $result.details.ruff = $ruffRes
          # attempt to parse ruff JSON if ok
          if ($ruffRes.ok -and $ruffRes.output) {
            try { $result.details.ruff_parsed = $ruffRes.output | ConvertFrom-Json -ErrorAction Stop } catch { $result.details.ruff_parse_error = $ruffRes.output }
          }
        } else {
          $result.details.ruff = @{ available = $false }
        }

        # Best-effort: run pyright (if installed)
        if (Get-Command pyright -ErrorAction SilentlyContinue) {
          $pyrightRes = Try-Run-External -CmdName pyright -Args @("--outputjson",$file)
          $result.details.pyright = $pyrightRes
          if ($pyrightRes.ok -and $pyrightRes.output) {
            try { $result.details.pyright_parsed = $pyrightRes.output | ConvertFrom-Json -ErrorAction Stop } catch { $result.details.pyright_parse_error = $pyrightRes.output }
          }
        } else {
          $result.details.pyright = @{ available = $false }
        }
      }

      ".ps1" {
        $result.handler = "powershell-parse"
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
      }

      default {
        $result.handler = "none"
        $result.status = "skipped"
        $result.details = @{ reason = "no handler for extension $ext" }
      }
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

    $results += $result
    Log-Line ("CHECK OK: {0} -> {1}" -f $file, $result.status)
  } catch {
    $err = $_.Exception.Message
    $results += [ordered]@{ file=$file; handler="internal"; status="error"; details=@{message=$err}; timestamp=(Get-Date).ToString("o") }
    Log-Line ("CHECK ERROR: {0} -> {1}" -f $file, $err)
  }
}

# write results JSON (array)
$results | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding utf8

# Also append each record to .runs/watch/<timestamp>.jsonl
$recordsPath = Join-Path $OutputDir ($timestamp + ".jsonl")
foreach ($r in $results) {
  $r | ConvertTo-Json -Depth 10 | Out-File -FilePath $recordsPath -Encoding utf8 -Append
}

Write-Host "Wrote results to $OutputPath"
exit 0