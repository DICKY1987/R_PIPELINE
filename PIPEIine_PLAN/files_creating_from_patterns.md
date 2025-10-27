Phase 1 — Streamlined watcher (fast feedback loop)

/watcher/build.ps1 → Invoke-Build “tasks with Inputs/Outputs” for incremental execution; define composite tasks (check.one → python.check, pwsh.check). (Plan: Workstream 1A tasks/deliverables; Patterns: incremental tasks + declarative deps)

/watcher/watch.ps1 → Debounced FileSystemWatcher with stability checks (500ms) to coalesce events. (Plan: 1A; Patterns: debounced watchers)

/watcher/watch.config.json, /watcher/watch.ignore → Centralized include/exclude + debounce tunables (config-first pattern). (Plan: 1B; Patterns: standardized manifests)

/watcher/pyproject.toml, /watcher/PSScriptAnalyzer.psd1 → Drop-in lint/test configs (ruff/pytest + PSSA) that mirror CI locally. (Plan: 1B; Patterns: toolchain configs)

/watcher/README.md → Quick-start runbook for local watch. (Plan: 1B)

/watcher/test_sample.py, /watcher/test_sample.ps1, /watcher/test_sample.Tests.ps1 → “Golden” fixtures to prove the loop. (Plan: 1C)

Phase 2 — Two-ID naming + scaffolding

/tools/nameguard/nameguard.py + nameguard.config.yaml → Naming policy enforcer (folder {module}__{TID}, file {TID}.{role}.{ext}) with --check/--fix. (Plan: 2A; Patterns: policy/config manifest + CLI wrapper)

/tools/nameguard/create_module.py → Module scaffolder that emits a standard pack ({TID}.run.py/.config.yaml/.schema.json/example.json, api.py, README). (Plan: 2B; Patterns: template/scaffold)

.pre-commit-config.yaml + /scripts/hooks/nameguard-hook.sh → Local guardrail mirroring CI. (Plan: 2C; Patterns: pre-commit)

Phase 3 — Backplane modules (drop-in templates)

Generate each module from your “5-Module” template pack (Acquisition, Transformation, State Change, Validation, Orchestration) so they’re deterministic, testable, and idempotent:

Ledger (LD-3X7) → append-only JSONL + signatures (+ tests).

Policy Pack (PP-9K2) → load OPA bundles + enforce schemas.

Cache/Rate-Limit (CR-4Y8) → file-cache + TTL.

Concurrency Controller (CC-2Z5) → file locks, work-stream isolation.

Observability (OB-6W1) → JSONL logs + minimal metrics.
(Plan: Workstream 3A–3E; Patterns: module scaffolds + strict module categories)

Intake, discovery & scoring (proven-process path)

phase_1_intake_routing/* (Plan Ingestor, Domain Router, Workstream Planner, Goal Normalizer, Query Expander) → Create from Acquisition/Transformation/Validation templates; each comes with Pester tests from the pack. (Plan: 4A)

phase_2_discovery_scoring/* (Discovery Adapters, Feature Extractors, Scorer) → Adopt “incremental tasks” + retry/backoff for adapters; score via policy-defined profiles. (Plan: 4B; Patterns: incremental + retry)

Guardrails, validation & CI (lift straight from patterns)

/scripts/validation/*.ps1 (format, lint, type, tests, SAST, secrets, policy) → Mirror SafePatch stages; each uses consistent “run wrapper” to capture exit codes/outputs. (Spec + Guardrails docs)

/.semgrep/.yml, /policy/opa/.rego, /policy/schemas/*.json → Policy-as-code packs. (Guardrails categories)

.pre-commit-config.yaml (already above) → Lines up local vs CI checks. (Spec “local validators”)

.github/workflows/quality.yml (+ optional composite action for SafePatch verify) → Reuse official actions (checkout/cache/upload-artifact with retries) and add cache restore-keys. (Patterns: composite reuse, cache strategy, resilient artifact upload)

/.runs/, /._machine/ledger.jsonl → Append-only run ledgers for audit. (Plan backplane + Spec)

Orchestration choices (keep it simple)

Prefer Invoke-Build (PowerShell) as your SSOT for orchestration (inputs/outputs + checkpoints) instead of writing a custom engine; your own notes already pivot to this “streamlined 15-file” approach. (Plan Phase 1/“watcher build”; Command context)

Agent & policy docs (copyable scaffolds)

AGENT_GUIDELINES.md, GUARDRAILS.md already define the behavior and categories—use as is and keep them authoritative in PRs. (Docs are complete and reusable)

What to generate first (lowest effort, highest leverage)

Watcher trio: build.ps1, watch.ps1, watch.config.json (debounce + incremental).

Pre-commit + tool configs: PSScriptAnalyzerSettings.psd1, pyproject.toml, .pre-commit-config.yaml.

Nameguard (validator + scaffold) to lock in Two-ID before creating modules.

Backplane five modules from your template pack (you already have the prompt/test scaffolds).

CI workflow using official actions with cache + resilient artifact upload.