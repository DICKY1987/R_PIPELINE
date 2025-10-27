Set-StrictMode -Version Latest

Describe 'Watcher debounce batching behavior' {
  BeforeAll {
    $script:root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    $script:watch = Join-Path $script:root 'watcher\watch.ps1'
    $script:runsDir = Join-Path $script:root '.runs\watch'
    New-Item -ItemType Directory -Force -Path $script:runsDir | Out-Null
  }

  It 'batches multiple changed files into one build run' {
    $tmp = New-Item -ItemType Directory -Path (Join-Path $env:TEMP ([Guid]::NewGuid()))
    $f1 = Join-Path $tmp.FullName 'a.ps1'
    $f2 = Join-Path $tmp.FullName 'b.ps1'
    Set-Content -Path $f1 -Value "Write-Output 'A'" -Encoding utf8
    Set-Content -Path $f2 -Value "Write-Output 'B'" -Encoding utf8

    # Use one-shot mode with isolated output dir to trigger a single debounced batch
    $outDir = Join-Path $env:TEMP ([Guid]::NewGuid())
    pwsh -NoLogo -NoProfile -File $script:watch -Path $tmp.FullName -DebounceMs 200 -Once -OutputDir $outDir | Out-Null

    $candidates = Get-ChildItem -Path $outDir -Filter *.json -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 30
    $found = $false
    foreach ($j in $candidates) {
      $arr = Get-Content -LiteralPath $j.FullName -Raw | ConvertFrom-Json
      $has1 = @($arr | Where-Object { $_.file -eq $f1 }).Count -gt 0
      $has2 = @($arr | Where-Object { $_.file -eq $f2 }).Count -gt 0
      if ($has1 -and $has2) { $found = $true; break }
    }
    $found | Should -BeTrue
  }
}
