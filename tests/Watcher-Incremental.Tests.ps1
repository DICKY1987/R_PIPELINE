Set-StrictMode -Version Latest

Describe 'Watcher build.ps1 results schema and incremental behavior' {
  BeforeAll {
    $script:root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    $script:build = Join-Path $script:root 'watcher\build.ps1'
    $script:runsDir = Join-Path $script:root '.runs\watch'
    New-Item -ItemType Directory -Force -Path $script:runsDir | Out-Null
  }

  It 'emits per-file JSON with steps[] and success boolean' {
    $tmp = New-Item -ItemType Directory -Path (Join-Path $env:TEMP ([Guid]::NewGuid()))
    $py = Join-Path $tmp.FullName 't.py'
    @(
      'def f():',
      '    return 42'
    ) | Set-Content -Path $py -Encoding utf8

    pwsh -NoLogo -NoProfile -File $script:build -Files $py -OutputDir $script:runsDir | Out-Null
    $json = Get-ChildItem -Path $script:runsDir -Filter *.json | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    $arr = Get-Content -LiteralPath $json.FullName -Raw | ConvertFrom-Json
    $rec = ($arr | Where-Object { $_.file -eq $py })
    $rec | Should -Not -Be $null
    $rec.file | Should -Be $py
    $rec.handler | Should -Not -BeNullOrEmpty
    $rec.status  | Should -Not -BeNullOrEmpty
    $rec.timestamp | Should -Not -BeNullOrEmpty
    # new schema expectations
    $rec.steps | Should -Not -Be $null
    @($rec.steps).Count | Should -BeGreaterThan 0
    @($rec.steps)[0].name | Should -Not -BeNullOrEmpty
    @($rec.steps)[0].elapsed_ms | Should -BeGreaterThan 0
    $rec.success | Should -BeOfType [bool]
  }

  It 'skips unchanged files on subsequent run (cache hit)' {
    $tmp = New-Item -ItemType Directory -Path (Join-Path $env:TEMP ([Guid]::NewGuid()))
    $ps1 = Join-Path $tmp.FullName 't.ps1'
    Set-Content -Path $ps1 -Value "# noop`nWrite-Output 'hi'" -Encoding utf8

    # first run
    pwsh -NoLogo -NoProfile -File $script:build -Files $ps1 -OutputDir $script:runsDir | Out-Null
    $firstJson = Get-ChildItem -Path $script:runsDir -Filter *.json | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    Start-Sleep -Milliseconds 200
    # second run without changes
    pwsh -NoLogo -NoProfile -File $script:build -Files $ps1 -OutputDir $script:runsDir | Out-Null
    $secondJson = Get-ChildItem -Path $script:runsDir -Filter *.json | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    $arr2 = Get-Content -LiteralPath $secondJson.FullName -Raw | ConvertFrom-Json
    $rec2 = ($arr2 | Where-Object { $_.file -eq $ps1 })
    $rec2 | Should -Not -Be $null
    $rec2.status | Should -Be 'skipped'
    $rec2.details.cache.hit | Should -BeTrue
  }
}


