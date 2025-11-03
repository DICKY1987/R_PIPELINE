Set-StrictMode -Version Latest

Describe 'Documentation updates' {
  It 'includes merge and rerere guidance' {
    Test-Path 'docs/merge/README.md' | Should -BeTrue
    (Get-Content -LiteralPath 'docs/merge/README.md' -Raw) | Should -Match 'rerere'
  }

  It 'documents merge-train workflow triggers' {
    Test-Path 'docs/ci/merge-train.md' | Should -BeTrue
    (Get-Content -LiteralPath 'docs/ci/merge-train.md' -Raw) | Should -Match 'workflow_dispatch'
  }

  It 'documents worktree orchestration' {
    Test-Path 'docs/workflows/worktrees.md' | Should -BeTrue
    (Get-Content -LiteralPath 'docs/workflows/worktrees.md' -Raw) | Should -Match 'New-ToolWorktree'
  }

  It 'documents MCP usage overview' {
    Test-Path 'docs/mcp/overview.md' | Should -BeTrue
  }

  It 'documents AI guardrails' {
    Test-Path 'docs/ai/guardrails.md' | Should -BeTrue
    (Get-Content -LiteralPath 'docs/ai/guardrails.md' -Raw) | Should -Match 'SafePatch'
  }

  It 'documents branch protections and setup requirements' {
    Test-Path 'docs/ci/protections.md' | Should -BeTrue
    Test-Path 'docs/setup/windows.md' | Should -BeTrue
  }
}
