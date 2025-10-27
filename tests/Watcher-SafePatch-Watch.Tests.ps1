Set-StrictMode -Version Latest

Describe 'watch.ps1 passes SafePatch flags to build and emits SafePatch details' {
  BeforeAll {
    $script:root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    $script:watch = Join-Path $script:root 'watcher\watch.ps1'
    $script:runsDir = Join-Path $script:root '.runs\watch'
    New-Item -ItemType Directory -Force -Path $script:runsDir | Out-Null
  }

  It 'emits SafePatch details when invoked with -EnableSafePatch/-SafePatchPath' {
    $tmp = New-Item -ItemType Directory -Path (Join-Path $env:TEMP ([Guid]::NewGuid()))

    # Fake SafePatch tool that returns JSON
    $safePatch = Join-Path $tmp.FullName 'safepatch.ps1'
    @(
      '#!/usr/bin/env pwsh',
      'param([Parameter()][string]$Path)',
      '$obj = @{ ok = $true; issues = @(@{ id = "TEST002"; severity = "info"; path = $Path }) }',
      '$obj | ConvertTo-Json -Depth 5'
    ) | Set-Content -Path $safePatch -Encoding utf8

    # Simple Python file to trigger routing
    $py = Join-Path $tmp.FullName 'x.py'
    @('x=1') | Set-Content -Path $py -Encoding utf8

    pwsh -NoLogo -NoProfile -File $script:watch -Path $tmp.FullName -RunForMs 50 -OutputDir $script:runsDir -EnableSafePatch -SafePatchPath $safePatch | Out-Null

    $json = Get-ChildItem -Path $script:runsDir -Filter *.json | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    $arr = Get-Content -LiteralPath $json.FullName -Raw | ConvertFrom-Json
    $rec = ($arr | Where-Object { $_.file -eq $py })
    $rec | Should -Not -Be $null
    $rec.details.SafePatch | Should -Not -Be $null
    $rec.details.SafePatch.ok | Should -BeTrue
    (@($rec.steps | Where-Object { $_.name -eq 'safepatch' }).Count) | Should -Be 1
  }
}
