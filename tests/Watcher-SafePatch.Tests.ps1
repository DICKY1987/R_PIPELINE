Set-StrictMode -Version Latest

Describe 'Watcher SafePatch adapter (optional, fail-soft)' {
  BeforeAll {
    $script:root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    $script:build = Join-Path $script:root 'watcher\build.ps1'
    $script:runsDir = Join-Path $script:root '.runs\watch'
    New-Item -ItemType Directory -Force -Path $script:runsDir | Out-Null
  }

  It 'populates details.SafePatch when enabled and tool provided' {
    $tmp = New-Item -ItemType Directory -Path (Join-Path $env:TEMP ([Guid]::NewGuid()))
    $safePatch = Join-Path $tmp.FullName 'safepatch.ps1'
    @(
      '#!/usr/bin/env pwsh',
      'param([Parameter()][string]$Path)',
      # Emit deterministic JSON so the adapter can parse reliably
      '$obj = @{ ok = $true; issues = @(@{ id = "TEST001"; severity = "low"; path = $Path }) }',
      '$obj | ConvertTo-Json -Depth 5'
    ) | Set-Content -Path $safePatch -Encoding utf8

    $py = Join-Path $tmp.FullName 't.py'
    @(
      'def f():',
      '    return 1'
    ) | Set-Content -Path $py -Encoding utf8

    pwsh -NoLogo -NoProfile -File $script:build -Files $py -OutputDir $script:runsDir -EnableSafePatch -SafePatchPath $safePatch | Out-Null
    # Find the newest results file that contains our target record (robust against concurrent writes)
    $rec = $null
    foreach ($cand in (Get-ChildItem -Path $script:runsDir -Filter *.json | Sort-Object LastWriteTime -Descending)) {
      try {
        $data = Get-Content -LiteralPath $cand.FullName -Raw | ConvertFrom-Json
      } catch { continue }
      $records = if ($data -is [System.Array]) { $data } else { @($data) }
      $match = $records | Where-Object { $_.file -eq $py } | Select-Object -First 1
      if ($match) { $rec = $match; break }
    }
    $rec | Should -Not -Be $null
    $rec.details.SafePatch | Should -Not -Be $null
    $rec.details.SafePatch.ok | Should -BeTrue
    @($rec.details.SafePatch.issues).Count | Should -BeGreaterThan 0
    # Step should be recorded
    (@($rec.steps | Where-Object { $_.name -eq 'safepatch' }).Count) | Should -Be 1
  }
}
