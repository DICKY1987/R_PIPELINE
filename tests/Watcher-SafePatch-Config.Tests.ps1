Set-StrictMode -Version Latest

Describe 'watch.ps1 reads SafePatch config' {
  BeforeAll {
    $script:root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    $script:watch = Join-Path $script:root 'watcher\watch.ps1'
    $script:cfgPath = Join-Path $script:root 'watcher\watch.config.json'
    $script:runsDir = Join-Path $script:root '.runs\watch'
    New-Item -ItemType Directory -Force -Path $script:runsDir | Out-Null
    # Backup config
    $script:cfgBackup = Get-Content -LiteralPath $script:cfgPath -Raw
  }

  AfterAll {
    if ($script:cfgBackup) { Set-Content -LiteralPath $script:cfgPath -Value $script:cfgBackup -Encoding utf8 }
  }

  It 'enables SafePatch via config without CLI flags' {
    $tmp = New-Item -ItemType Directory -Path (Join-Path $env:TEMP ([Guid]::NewGuid()))
    # Fake SafePatch tool
    $safePatch = Join-Path $tmp.FullName 'safepatch.ps1'
    @(
      '#!/usr/bin/env pwsh',
      'param([Parameter()][string]$Path)',
      '$obj = @{ ok = $true; issues = @(@{ id = "CONF001"; severity = "low"; path = $Path }) }',
      '$obj | ConvertTo-Json -Depth 5'
    ) | Set-Content -Path $safePatch -Encoding utf8

    # Write config with SafePatch enabled
    $cfg = Get-Content -LiteralPath $script:cfgPath -Raw | ConvertFrom-Json
    $cfg.SafePatch = @{ enabled = $true; path = $safePatch }
    ($cfg | ConvertTo-Json -Depth 5) | Set-Content -LiteralPath $script:cfgPath -Encoding utf8

    # Minimal file to trigger routing
    $py = Join-Path $tmp.FullName 'conf.py'
    @('x=2') | Set-Content -Path $py -Encoding utf8

    # Invoke watcher without SafePatch flags; rely on config
    pwsh -NoLogo -NoProfile -File $script:watch -Path $tmp.FullName -RunForMs 50 -OutputDir $script:runsDir | Out-Null

    $json = Get-ChildItem -Path $script:runsDir -Filter *.json | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    $arr = Get-Content -LiteralPath $json.FullName -Raw | ConvertFrom-Json
    $rec = ($arr | Where-Object { $_.file -eq $py })
    $rec | Should -Not -Be $null
    $rec.details.SafePatch | Should -Not -Be $null
    $rec.details.SafePatch.ok | Should -BeTrue
  }
}

