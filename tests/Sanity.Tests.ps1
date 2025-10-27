Set-StrictMode -Version Latest
Describe 'Repository Sanity' {
  It 'guardrails scaffolding exists' {
    Test-Path 'docs/STYLEGUIDE.md' | Should -BeTrue
    Test-Path 'tools/Verify.ps1'   | Should -BeTrue
  }

  It 'defines latency target for cross-platform burst workstream' {
    $root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    $workstreamPath = Join-Path $root 'workstreams/cross_platform_burst_reliability.json'
    $workstream = Get-Content -LiteralPath $workstreamPath -Raw | ConvertFrom-Json

    $workstream.contracts.latency_goal_ms | Should -BeLessThanOrEqual 250
    $workstream.validation | Should -Contain 'Latency histogram under 250ms p99 on both OSes'
  }
}

Describe 'Performance telemetry workstream' {
  It 'records metrics snapshot output path' {
    $path = 'workstreams/performance_telemetry.json'
    $json = Get-Content -Raw -Path $path | ConvertFrom-Json

    $json.metrics_snapshot | Should -Not -BeNullOrEmpty
    $json.metrics_snapshot.output_path | Should -Be '.runs/ci/perf.json'
    Test-Path $json.metrics_snapshot.output_path | Should -BeTrue
  }
}

