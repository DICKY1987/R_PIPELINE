When lots of agents are spitting out hundreds of files, you tame drift and “hallucinated code” by building a guardrail stack that (a) constrains generation up front, (b) validates every artifact automatically, and (c) blocks merges unless everything passes. Here’s a pragmatic, battle-tested setup you can copy.

Guardrail stack (from prompt → PR → main)
1) Repo scaffolding & style that tools can enforce

EditorConfig at repo root to lock whitespace, line endings, encodings across editors and OSes. 
spec.editorconfig.org
+2
editorconfig.org
+2

Conventional Commits for machine-readable history + changelog/semver automation; enforce via a commit-msg hook. 
conventionalcommits.org
+1

CODEOWNERS to route reviews to subject owners automatically. 
GitHub Docs
+1

Branch protection rules so merges require passing checks, reviews, and linear history. 
GitHub Docs
+1

2) “Structured output” constraints for AI agents (stop nonsense early)

Wrap agents with libraries that constrain generation to schemas/grammars so they can’t invent shapes or fields:

NVIDIA NeMo Guardrails (Colang flows, topic & tool-use control). 
NVIDIA Docs
+2
NVIDIA Docs
+2

Guardrails AI (Pydantic/RAIL schemas, validators, JSON guarantees). 
guardrails
+2
guardrails
+2

Guidance / llguidance (regex/CFG-level constrained decoding). 
GitHub
+2
GitHub
+2

Outlines (type/JSON/grammar-guaranteed decoding; LangChain provider available). 
Hugging Face
+3
dottxt-ai.github.io
+3
GitHub
+3

LMQL (typed prompts + constraint-guided generation). 
lmql.ai
+2
lmql.ai
+2

These frameworks make the agent emit only valid JSON/specs/tests your CI expects, which slashes “made-up cmdlets/functions.”

3) Language-specific static analysis (catch errors before runtime)

PowerShell: PSScriptAnalyzer in dev and CI; add custom rules (ban aliases, enforce Approved Verbs, module manifests). 
Microsoft Learn
+2
Microsoft Learn
+2

Python: Ruff (lint/format) + mypy (types). 
mypy-lang.org
+3
Astral Docs
+3
Astral
+3

TypeScript/JS: tsconfig.json with "strict": true (plus ESLint/tsc in CI). 
typescriptlang.org
+1

Semgrep for repo-wide, language-agnostic rules (security & code patterns) that you can tune per policy. 
Semgrep
+1

4) Test-first generation and gating

PowerShell tests: Pester (unit/integration/mocking) and make agents generate tests with the code. Gate PRs on Pester pass. 
Pester
+1

Property-based tests (e.g., Hypothesis for Python) and mutation testing (e.g., Stryker for JS) are great upgrades later.

5) Pre-commit hooks (local & CI-mirrored)

Use pre-commit to run linters/formatters/secret scans before any commit; mirror the exact hooks in CI so nothing slips in. 
Pre-Commit
+2
GitHub
+2

6) Policy-as-code for configs produced by agents

OPA + Conftest: write Rego policies to validate YAML/JSON/TOML emitted by agents (e.g., “scripts must import approved modules,” “only approved cmdlets,” “no dangerous params”). Run in pre-commit and CI. 
Conftest
+3
Open Policy Agent
+3
Open Policy Agent
+3

7) Dependency hygiene to avoid drift

Renovate bot auto-PRs pin/upgrade dependency versions (monorepos supported). Gate merges on tests. 
Renovate Docs
+1

8) Build graph + caching for scale (monorepos)

If the project grows big: Nx (task graph, affected-only runs, caching) or Bazel (language-agnostic, hermetic builds/tests). They shrink CI time and ensure everything actually builds. 
Nx
+2
GitHub
+2

9) CI gates that block hallucinations

In GitHub Actions (example components & references):

PSScriptAnalyzer step (fail on any error/warn). 
GitHub
+1

Run Pester step with coverage & test artifacts. 
GitHub Docs
+1

Semgrep scan for patterns/security. 
Semgrep

pre-commit CI to re-run exact local hooks server-side. 
Pre-Commit

Conftest policy checks over any generated configs/specs. 
Conftest

Enforce via branch protection rules + CODEOWNERS review. 
GitHub Docs
+2
GitHub Docs
+2

10) PowerShell-specific hardening patterns for agents to follow

Every script/module template should include:
#Requires -Version 5.1, Set-StrictMode -Version Latest, $ErrorActionPreference='Stop', no aliases, Approved Verbs, explicit param() with types, and Pester tests for Import-Module, Get-Command sanity. Enforce via PSScriptAnalyzer rules & tests. 
Microsoft Learn
+1

11) “Contract-first” generation to stop made-up functions

Make agents generate against contracts: OpenAPI/JSON-Schema/Pydantic models/TypeScript types. Validate artifacts in CI so any call to a non-existent symbol or wrong shape fails fast (Semgrep rules + type checkers + Pester). (OpenAPI & JSON Schema are the usual contract sources.) 
spec.editorconfig.org

12) Runbooks for agents (“how to behave”)

Give each coding agent a short policy it must follow:

Only use functions/cmdlets that exist in this repo or in an allowed allowlist.

If you propose a new helper, also generate its file + tests in the same PR.

Emit a change plan JSON (schema-validated) and Pester tests before writing code (tools above will reject non-conforming output).

Minimal, copy-pasteable setup (PowerShell-centric, works cross-lang)

.editorconfig (root)

root = true

[*]
end_of_line = lf
insert_final_newline = true
charset = utf-8
indent_style = space
indent_size = 2


.pre-commit-config.yaml

repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.6.0
    hooks:
      - id: check-yaml
      - id: end-of-file-fixer
      - id: trailing-whitespace
  - repo: https://github.com/awslabs/git-secrets
    rev: 1.3.0
    hooks:
      - id: git-secrets
  - repo: local
    hooks:
      - id: psscriptanalyzer
        name: PSScriptAnalyzer
        entry: pwsh -NoLogo -NoProfile -Command "Install-Module PSScriptAnalyzer -Scope CurrentUser -Force; Invoke-ScriptAnalyzer -Path . -Recurse -Severity Error,Warning; if($LASTEXITCODE -ne 0){exit 1}"
        language: system
        files: \.(ps1|psm1|psd1)$
      - id: semgrep
        name: semgrep
        entry: semgrep scan --config=auto
        language: system
        pass_filenames: false


(Pre-commit runs locally; we mirror these steps in CI.) 
Pre-Commit
+1

.github/workflows/ci.yml (GitHub Actions)

name: CI
on:
  pull_request:
  push: { branches: [main] }
jobs:
  ps:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup PowerShell modules
        run: |
          Set-PSRepository PSGallery -InstallationPolicy Trusted
          Install-Module PSScriptAnalyzer -Force
          Install-Module Pester -Force
      - name: Lint (PSScriptAnalyzer)
        uses: microsoft/psscriptanalyzer-action@v1.0
        with:
          path: .\
          recurse: true
          output: results.sarif
      - name: Test (Pester)
        uses: PSModule/Invoke-Pester@v1
        with:
          Script: ./tests
          EnableExit: true
  semgrep:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: pipx install semgrep && semgrep scan --config=auto


GitHub
+2
GitHub
+2

CODEOWNERS (example)

# PowerShell modules
src/powershell/**  @your-org/ps-core-team
# CI & policies
.github/**         @your-org/devex


GitHub Docs

Branch protection: Require “CI” workflow success + 1+ CODEOWNERS review; disallow force-pushes. 
GitHub Docs
+1

Conftest (policy example for generated task JSON)
policy/tasks.rego

package tasks

deny[msg] {
  input.name == ""
  msg := "task.name is required"
}

deny[msg] {
  not input.owner
  msg := "task.owner is required"
}


Run: conftest test artifacts/tasks/*.json. 
Conftest

Renovate (dependency drift) – add renovate.json and enable the bot. 
Renovate Docs

How this stops “made-up cmdlets” & symbol drift

Constrained generation (Guardrails/Outlines/Guidance/LMQL) prevents invalid shapes and enforces the plan/test schema before code is written. 
guardrails
+2
dottxt-ai.github.io
+2

PSScriptAnalyzer + custom rules flag unapproved verbs, aliases, missing module manifests, etc. 
Microsoft Learn

Pester asserts that referenced functions/cmdlets actually exist (Get-Command checks), and modules import cleanly. 
Pester

Semgrep bans anti-patterns or forbidden APIs across the repo. 
Semgrep

Conftest rejects malformed agent outputs (work plans, configs) before they reach code. 
Conftest

Branch protection + CODEOWNERS make it impossible to merge until all checks pass and owners sign off. 
GitHub Docs
+1

Recommended tools (shortlist)

PowerShell: PSScriptAnalyzer, Pester (with GitHub Actions integrations). 
Microsoft Learn
+1

Cross-language: pre-commit, Semgrep, OPA/Conftest, Renovate. 
Renovate Docs
+3
Pre-Commit
+3
Semgrep
+3

Monorepo scale: Nx or Bazel for build/test graphing & caching. 
Nx
+1

AI guardrails: NeMo Guardrails, Guardrails AI, Guidance/Outlines/LMQL. 
dottxt-ai.github.io
+3
NVIDIA Docs
+3
guardrails
+3

Quick start order (you can do this today)

Add .editorconfig, CODEOWNERS, Conventional Commits note in CONTRIBUTING. 
editorconfig.org
+2
GitHub Docs
+2

Install pre-commit and enable PSScriptAnalyzer + Semgrep hooks. 
Pre-Commit

Add the CI workflow above + enable branch protection on main. 
GitHub
+1

Introduce Pester tests for every new script (agents must generate tests). 
Pester

Wrap your AI agents with Guardrails/Outlines/Guidance so they can only emit your JSON “work plan” + test stubs. 
guardrails
+2
dottxt-ai.github.io
+2

Add Conftest policies to reject malformed plans/configs. 
Conftest

Turn on Renovate to eliminate dependency drift