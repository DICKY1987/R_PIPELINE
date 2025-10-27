Set-StrictMode -Version Latest

Describe 'Watcher burst reliability' {
  BeforeAll {
    $script:root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    $script:watch = Join-Path $script:root 'watcher\watch.ps1'
  }

  It 'captures 100 rapid-created files without loss' {
    $tmp = New-Item -ItemType Directory -Path (Join-Path $env:TEMP ([Guid]::NewGuid()))
    $outDir = Join-Path $env:TEMP ([Guid]::NewGuid())

    1..100 | ForEach-Object {
      $f = Join-Path $tmp.FullName ("f{0}.ps1" -f $_)
      Set-Content -Path $f -Value "Write-Output '$_'" -Encoding utf8
    }

    pwsh -NoLogo -NoProfile -File $script:watch -Path $tmp.FullName -RunForMs 500 -DebounceMs 100 -OutputDir $outDir | Out-Null

    $json = Get-ChildItem -Path $outDir -Filter *.json -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    $json | Should -Not -Be $null
    $arr = Get-Content -LiteralPath $json.FullName -Raw | ConvertFrom-Json
    # Only count files under our temp burst directory
    $records = @($arr | Where-Object { $_.file -like (Join-Path $tmp.FullName '*') })
    $records.Count | Should -Be 100
    # Sanity: all are ok or skipped (should be ok on first run)
    (@($records | Where-Object { $_.status -in @('ok','skipped') }).Count) | Should -Be 100
  }
}

