Love it — here’s a **manifest-driven, machine-first** approach plus **concrete file lists per module** so every folder holds the scripts truly responsible for that module (no prose docs, just configs, schemas, and code).

# Approach (1-liner)

Run a **manifest-driven, AI-operated pipeline**: one source-of-truth `pipeline.yml` feeds modular, headless CLI executors; each module exposes a tiny contract (schema + config), produces machine logs/ledger, and emits patchable artifacts — the **only human-optional output** is the final script/workflow.

---

# What every module folder should have (the “common 5”)

* `run.py` — the module’s headless entrypoint (reads config/contract, writes results).
* `config.yaml` — tunables for this module only (timeouts, limits, toggles).
* `contract.schema.json` — JSON Schema for this module’s inputs/outputs.
* `contract.example.json` — minimal, valid example payload for local runs.
* `logs/` (created at runtime) — compact JSONL logs (module-scoped).

> Optional per module when relevant: `adapters/`, `templates/`, `rules/`, `tests/`, `tools/` (PS scripts), `schemas/` (extra).

---

# Module folders and files (minimal, practical sets)

## `/modules/plan_ingestor/`

* `run.py` (parse & normalize `proposed_change_plan.json`)
* `normalize_plan.py`
* `contract.schema.json` (plan in → normalized plan out)
* `config.yaml` (allow/deny ops, path filters)
* `tests/smoke_plan.json`

## `/modules/workstream_planner/`

* `run.py`
* `graph_partition.py` (deps → independent work-streams)
* `locks.py` (single-writer/file locks)
* `contract.schema.json`
* `config.yaml` (max_concurrency, lock TTL)

## `/modules/domain_router/`

* `run.py`
* `route.py` (path→domain mapping)
* `rules.yaml` (routing rules; globs, filetypes)
* `contract.schema.json`
* `config.yaml`

## `/modules/goal_normalizer/`

* `run.py`
* `normalize_goal.py`
* `synonyms.yaml` (capability vocab)
* `contract.schema.json`
* `config.yaml`

## `/modules/query_expander/`

* `run.py`
* `expand.py`
* `synonyms.yaml` (shared or vendored)
* `queries.schema.json`
* `config.yaml` (rounds, dedupe, anchors)

## `/modules/discovery_adapters/`

* `run.py` (orchestrates adapters)
* `adapters/github.py` `adapters/pypi.py` `adapters/docs.py`
* `rate_limit.py` `cache_store.py`
* `evidence.schema.json` (JSONL item shape)
* `config.yaml` (tokens, endpoints, backoff)

## `/modules/feature_extractors/`

* `run.py`
* `extract_license.py` `extract_activity.py` `extract_examples.py`
* `features.schema.json`
* `config.yaml`

## `/modules/scorer/`

* `run.py`
* `scoring.py`
* `profiles/default.yaml` (weights: maintenance/docs/adoption/tests/etc.)
* `policy_gates.yaml` (license allowlist, freshness windows)
* `scores.schema.json`

## `/modules/synthesizer/`

* `run.py`
* `synth.py` (capability→template resolver)
* `renderers/python_invoke.py` `renderers/powershell_ib.py` `renderers/gha.py`
* `templates/` (invoke_watchfiles_v1/, ib_watch_v1/, gha_ci_v1/)
* `artifact.schema.json`
* `config.yaml` (template prefs, fallbacks)

## `/modules/structured_patcher/`

* `run.py`
* `patch_ast_py.py` (Python AST edits)
* `patch_ps1.py` (PowerShell structured edits)
* `patch_toml.py` `patch_yaml.py`
* `patch_plan.schema.json`
* `config.yaml` (conflict policy, idempotency)

## `/modules/guardrails/`

* `run.py`
* `lint_py.py` (ruff/black wrappers)  ·  `lint_ps.ps1` (PSSA)
* `schema_check.py` (JSON/YAML/TOML)
* `rules/structure.yaml` `rules/policy.yaml`
* `results.schema.json`
* `config.yaml` (autofix=true, max_changes)

## `/modules/verifier/`

* `run.py`
* `verify_py.py` (pytest smoke)  ·  `verify_ps.ps1` (Pester smoke)
* `probe.py` (short runtime probe with timeout)
* `matrix.yaml` (OS/tool matrix)
* `verification.schema.json`
* `config.yaml` (timeouts, retries)

## `/modules/selector/`

* `run.py`
* `select.py` (score × verify × policy)
* `thresholds.yaml`
* `selection.schema.json`
* `config.yaml`

## `/modules/exporter/`

* `run.py`
* `export.py` (write champion to `/out`, build patch)
* `pr_metadata.json.tmpl` (minimal machine PR body)
* `artifact_index.schema.json`
* `config.yaml` (output dirs, naming)

## `/modules/ledger/`

* `run.py`
* `append.py` (atomic JSONL appends, ULIDs)
* `ledger.schema.json`
* `config.yaml` (rotation, redaction)

## `/modules/policy_pack/`

* `run.py` (policy loader/validator)
* `policy.yaml` (licenses, maintenance, OS matrix)
* `scoring_profiles/` (overrides)
* `policy.schema.json`

## `/modules/cache_and_ratelimit/`

* `run.py`
* `cache.py` (TTL, keys, hydrate)
* `ratelimit.py` (token bucket)
* `config.yaml`

## `/modules/concurrency_controller/`

* `run.py`
* `queue.py` (work-queue, fairness)
* `limits.yaml` (max workers, CPU caps)
* `config.yaml`

## `/modules/error_auto_repair/`

* `run.py`
* `autofix_py.py` (ruff/black/org-imports orchestration)
* `autofix_ps.ps1` (PSSA -Fix)
* `fix_rules.yaml`
* `config.yaml`

## `/modules/spike_harness/`

* `run.py`
* `harness.py` (ephemeral venv/container trials)
* `scenarios/` (*.yaml quick trials)
* `spike.schema.json`
* `config.yaml`

## `/modules/provenance_rollback/`

* `run.py`
* `provenance.py` (embed template+source ULIDs in headers)
* `rollback.py` (git revert/restore helpers)
* `header.tmpl`
* `config.yaml`

## `/modules/ci_precommit_integrator/`

* `run.py`
* `emit_precommit.py` (write .pre-commit-config.yaml)
* `emit_ci.py` (write .github/workflows/*)
* `config.yaml`

## `/modules/playbook_promoter/`

* `run.py`
* `promote.py` (turn chosen solutions → reusable playbooks)
* `playbook.schema.json`
* `config.yaml`

## `/modules/observability/`

* `run.py`
* `metrics.py` (emit counters/timers)
* `log_conf.yaml` (JSON log format)
* `dash/` (lightweight dashboard specs)

## `/modules/knowledge_reuse/`

* `run.py`
* `reuse.py` (reuse champion by capability key)
* `index.json` (capability→artifact map)
* `config.yaml`

---

# Orchestrator, manifest, GUI (top-level pieces)

```
/manifests/
  pipeline.yml              # single source of truth
  schema.json               # validates pipeline.yml
/orchestrator/
  run.py                    # reads manifest, calls modules in order
  io_bus.py                 # JSONL in/out wiring between modules
  errors.py                 # common exceptions
/out/                       # champion artifacts & patches
/._machine/                 # append-only global ledger, caches
/gui/
  app.py                    # Python GUI (control surface)
  api.py                    # talks to orchestrator (subprocess IPC)
  views/                    # status, work-streams, diff, PR link
```

---

## Notes to keep it tight & headless

* Every `run.py` should accept `--in <json>` and `--out <json>` (stdin/stdout OK) to chain modules deterministically.
* Prefer **Python** for module internals; use **PowerShell** scripts only inside `tools/` where platform-specific checks are needed.
* Keep **schemas small** and **examples real** — that’s your fastest local smoke test.
* The GUI never writes code; it only **spawns modules**, streams JSONL, and shows the final **diff/PR**.

If you want, I can generate empty folders + stub files (with minimal schema/config scaffolds) so you can drop this into a repo and start wiring modules one by one.
