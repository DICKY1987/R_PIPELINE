Set-StrictMode -Version Latest

Describe 'Workstream WS-06 contracts' {
  It 'defines cache key formats for each cache target' {
    $workstream = Get-Content 'workstreams/ci_workflows_caching.json' -Raw | ConvertFrom-Json
    $cacheKeys = $workstream.contracts.cache_keys

    $cacheKeys | Should -Not -BeNullOrEmpty
    $cacheKeys.pip      | Should -Match '^pip-'
    $cacheKeys.pwsh     | Should -Match '^psmodules-'
    $cacheKeys.watcher  | Should -Match '^watch-cache-'
  }
}
