Set-StrictMode -Version Latest
Describe 'Repository Sanity' {
  It 'guardrails scaffolding exists' {
    Test-Path 'docs/STYLEGUIDE.md' | Should -BeTrue
    Test-Path 'tools/Verify.ps1'   | Should -BeTrue
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

