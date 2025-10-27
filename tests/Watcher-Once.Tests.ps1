Set-StrictMode -Version Latest

Describe 'Watcher one-shot mode (-Once) does not error and emits results' {
  BeforeAll {
    $script:root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    $script:watch = Join-Path $script:root 'watcher\watch.ps1'
    $script:runsDir = Join-Path $script:root '.runs\watch'
    New-Item -ItemType Directory -Force -Path $script:runsDir | Out-Null
  }

  It 'runs without subscription errors and writes a results file' {
    $tmp = New-Item -ItemType Directory -Path (Join-Path $env:TEMP ([Guid]::NewGuid()))
    $ps1 = Join-Path $tmp.FullName 't.ps1'
    Set-Content -Path $ps1 -Value "# sample`nWrite-Output 'ok'" -Encoding utf8

    $pre = Get-ChildItem -Path $script:runsDir -Filter *.json -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1

    pwsh -NoLogo -NoProfile -File $script:watch -Path $tmp.FullName -Once | Out-Null
    $exit = $LASTEXITCODE

    $post = Get-ChildItem -Path $script:runsDir -Filter *.json -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1

    $exit | Should -Be 0
    if ($pre -and $post) {
      ($post.LastWriteTime -ge $pre.LastWriteTime) | Should -BeTrue
    } else {
      # At least one result file should exist after run
      Test-Path $post.FullName | Should -BeTrue
    }
  }
}

