param(
    [string]$Root = (Get-Location).Path,
    [string]$MappingFile = (Join-Path (Get-Location).Path 'filemapping.json'),
    [string]$ModulesRoot = (Join-Path (Get-Location).Path 'PIPELINE_MODS'),
    [switch]$WhatIf
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message"
}

function Ensure-Directory {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path | Out-Null
    }
}

function Get-Mapping {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Mapping file not found: $Path"
    }
    $raw = Get-Content -LiteralPath $Path -Raw
    $json = $null
    # Prefer fenced code block labeled json (singleline via (?s))
    if ($raw -match '(?s)```json\s*(\[.*?\])\s*```') {
        $json = $Matches[1]
    }
    elseif ($raw -match '(?s)(\[\s*\{.*\}\s*\])') {
        $json = $Matches[1]
    }
    if (-not $json) {
        throw "Unable to locate a JSON array in mapping file. Ensure it contains a JSON array of entries."
    }
    try {
        return ($json | ConvertFrom-Json)
    }
    catch {
        throw "Failed to parse mapping JSON: $($_.Exception.Message)"
    }
}

function Expand-FileNames {
    param([string]$Spec)
    # Handle patterns like "madchat1.md through madchat13.md"
    $throughPattern = '^(?<base1>[^0-9\\/]+?)(?<start>\d+)(?<ext>\.[A-Za-z0-9_.-]+)\s+through\s+(?<base2>[^0-9\\/]+?)(?<end>\d+)(?<ext2>\.[A-Za-z0-9_.-]+)$'
    if ($Spec -match $throughPattern) {
        $base1 = $Matches.base1
        $base2 = $Matches.base2
        $start = [int]$Matches.start
        $end = [int]$Matches.end
        $ext = $Matches.ext
        $ext2 = $Matches.ext2
        if ($base1 -ne $base2 -or $ext -ne $ext2) {
            # Fallback to literal if mismatch
            return ,$Spec
        }
        $width = $Matches.start.Length
        $names = @()
        for ($i = $start; $i -le $end; $i++) {
            $num = $i.ToString("D$width")
            $names += "$base1$num$ext"
        }
        return $names
    }
    return ,$Spec
}

function Remove-IfExists {
    param([string]$Path)
    if (Test-Path -LiteralPath $Path) {
        Remove-Item -LiteralPath $Path -Force
    }
}

Write-Info "Parsing mapping from '$MappingFile'"
$mapping = Get-Mapping -Path $MappingFile
Ensure-Directory -Path $ModulesRoot

$moved = 0
$copied = 0
$notFound = New-Object System.Collections.Generic.List[string]
$errors = New-Object System.Collections.Generic.List[string]

$rootFull = [System.IO.Path]::GetFullPath($Root)
$modsFull = [System.IO.Path]::GetFullPath($ModulesRoot)

foreach ($entry in $mapping) {
    $fileSpec = $entry.file_name
    $modules = @()
    if ($null -ne $entry.matched_modules) { $modules = @($entry.matched_modules) }
    if (-not $fileSpec) { continue }

    $candidateNames = Expand-FileNames -Spec $fileSpec
    $foundAnyForSpec = $false

    foreach ($cand in $candidateNames) {
        # Find files by exact name anywhere under root, excluding PIPELINE_MODS
        $found = Get-ChildItem -Path $rootFull -Recurse -File -ErrorAction SilentlyContinue |
                 Where-Object { $_.Name -eq $cand -and -not ($_.FullName.StartsWith($modsFull, [StringComparison]::InvariantCultureIgnoreCase)) }

        if (-not $found) {
            continue
        }
        $foundAnyForSpec = $true

        foreach ($src in $found) {
            if (-not $modules -or $modules.Count -eq 0) {
                Write-Info "No modules mapped for '$($src.FullName)'; skipping"
                continue
            }

            $destPaths = @()
            foreach ($m in $modules) {
                $destDir = Join-Path $ModulesRoot $m
                $destFile = Join-Path $destDir $src.Name
                $destPaths += $destFile
            }

            if ($destPaths.Count -eq 1) {
                $destFile = $destPaths[0]
                $destDir = Split-Path -Path $destFile -Parent
                Ensure-Directory -Path $destDir
                if ($WhatIf) {
                    Write-Host "[DRYRUN] Move '$($src.FullName)' -> '$destFile'"
                } else {
                    Remove-IfExists -Path $destFile
                    Move-Item -LiteralPath $src.FullName -Destination $destFile -Force
                }
                $moved++
            }
            else {
                # Multiple modules: move to first, copy to the rest
                $first = $destPaths[0]
                $firstDir = Split-Path -Path $first -Parent
                Ensure-Directory -Path $firstDir
                if ($WhatIf) {
                    Write-Host "[DRYRUN] Move '$($src.FullName)' -> '$first'"
                } else {
                    Remove-IfExists -Path $first
                    Move-Item -LiteralPath $src.FullName -Destination $first -Force
                }
                $moved++
                for ($i = 1; $i -lt $destPaths.Count; $i++) {
                    $dst = $destPaths[$i]
                    $dstDir = Split-Path -Path $dst -Parent
                    Ensure-Directory -Path $dstDir
                    if ($WhatIf) {
                        Write-Host "[DRYRUN] Copy '$first' -> '$dst'"
                    } else {
                        Remove-IfExists -Path $dst
                        Copy-Item -LiteralPath $first -Destination $dst -Force
                    }
                    $copied++
                }
            }
        }
    }

    if (-not $foundAnyForSpec) {
        $notFound.Add($fileSpec) | Out-Null
    }
}

Write-Host ""; Write-Info "Operation summary"
Write-Host ("Moved:   {0}" -f $moved)
Write-Host ("Copied:  {0}" -f $copied)
if ($notFound.Count -gt 0) {
    Write-Host ("Not found ({0}):" -f $notFound.Count)
    $notFound | Sort-Object -Unique | ForEach-Object { Write-Host "  - $_" }
}
