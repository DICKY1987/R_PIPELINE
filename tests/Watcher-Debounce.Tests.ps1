Set-StrictMode -Version Latest

Describe 'Watcher debounce batching behavior' {
  BeforeAll {
    $script:root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    $script:watch = Join-Path $script:root 'watcher\watch.ps1'
    $script:runsDir = Join-Path $script:root '.runs\watch'
    New-Item -ItemType Directory -Force -Path $script:runsDir | Out-Null
  }

  It 'batches rapid multi-saves into a single build invocation' {
    $tmp = New-Item -ItemType Directory -Path (Join-Path $env:TEMP ([Guid]::NewGuid()))
    $testFile = Join-Path $tmp.FullName 'burst.ps1'

    # Count existing result files
    $before = @(Get-ChildItem -Path $script:runsDir -Filter *.json -ErrorAction SilentlyContinue)

    # Start watcher for a short, bounded time window
    $debounceMs = 300
    $runForMs = 1500
    $args = @(
      '-NoLogo','-NoProfile','-File', $script:watch,
      '-Path', $tmp.FullName,
      '-DebounceMs', $debounceMs,
      '-RunForMs', $runForMs
    )
    $job = Start-Process -FilePath pwsh -ArgumentList $args -PassThru -WindowStyle Hidden

    Start-Sleep -Milliseconds 200

    # Create the file, then modify it rapidly several times within debounce window
    Set-Content -Path $testFile -Value "# initial`nWrite-Output 'one'" -Encoding utf8
    1..5 | ForEach-Object {
      Start-Sleep -Milliseconds 40
      Add-Content -Path $testFile -Value "Write-Output 'tick $_'"
    }

    # Wait for watcher to finish its bounded run
    $null = $job.WaitForExit($runForMs + 1000)

    $after = @(Get-ChildItem -Path $script:runsDir -Filter *.json -ErrorAction SilentlyContinue)
    ($after.Count - $before.Count) | Should -Be 1

    $latest = $after | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    $arr = Get-Content -LiteralPath $latest.FullName -Raw | ConvertFrom-Json
    $rec = ($arr | Where-Object { $_.file -eq $testFile })
    $rec | Should -Not -Be $null
  }
}

