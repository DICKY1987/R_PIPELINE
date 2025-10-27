Set-StrictMode -Version Latest

Describe 'Pre-commit local developer experience' {
    BeforeAll {
        $scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
        $script:repoRoot = Resolve-Path (Join-Path $scriptRoot '..')
    }

    It 'defines the required pre-commit hooks' {
        $configPath = Join-Path $repoRoot '.pre-commit-config.yaml'
        if (-not (Test-Path -LiteralPath $configPath)) {
            throw ".pre-commit-config.yaml is missing"
        }

        $configText = Get-Content -LiteralPath $configPath -Raw
        $configText | Should -Match 'repo:\s+https://github.com/psf/black'
        $configText | Should -Match 'repo:\s+https://github.com/astral-sh/ruff-pre-commit'
        $configText | Should -Match 'repo:\s+https://github.com/commitizen-tools/commitizen'
        $configText | Should -Match 'id:\s+pwsh-psscriptanalyzer'
        $configText | Should -Match 'id:\s+pwsh-check-one'
    }

    It 'documents installing the pre-commit hooks' {
        $contributingPath = Join-Path $repoRoot 'CONTRIBUTING.md'
        if (-not (Test-Path -LiteralPath $contributingPath)) {
            throw 'CONTRIBUTING.md is missing setup instructions'
        }

        $docText = Get-Content -LiteralPath $contributingPath -Raw
        $docText | Should -Match 'pre-commit install'
        $docText | Should -Match 'pre-commit run --all-files'
    }
}
