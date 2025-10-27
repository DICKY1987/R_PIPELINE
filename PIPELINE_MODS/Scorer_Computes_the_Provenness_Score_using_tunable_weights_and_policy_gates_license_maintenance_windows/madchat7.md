This wraps cleanly around the discovery/synthesis pipeline you designed. Your three ops (edit/create/remove) + parallel work-streams are solid. Below is a refined, **AI-operated, machine-first blueprint** that preserves your intent, closes gaps, and makes it safer, faster, and fully chainable.

# Executive take

Your workflow is strong. To make it robust for AI-only operation at scale, add:

1. a **formal change plan** with dependency-aware work-streams,
2. a **domain router** that picks the right sub-pipeline per file type,
3. a **synthesis+verify loop** that treats *deliverables as tests*, and
4. deterministic **guardrails + auto-repair** before export.

---

# 1) Inputs & contracts (machine-first)

**proposed_change_plan.json** — emitted by the upstream “planner” prompt

```json
{
  "plan_uid": "ULID-...",
  "workstreams": [
    {
      "workstream_uid": "WS-001",
      "goal": "Add watch+lint+test pipeline",
      "ops": [
        {"op":"create","path":"tasks.py","domain":"python-script","deliverables":["watch:lint:test"]},
        {"op":"edit","path":"pyproject.toml","domain":"config","deliverables":["poe-tasks"]},
        {"op":"remove","path":"scripts/legacy_watch.py","domain":"python-script"}
      ],
      "deps_on": [],
      "acceptance": [{"type":"cli","cmd":"inv watch","timeout_s":5}]
    }
  ]
}
```

> Keep ops to **edit/create/remove** only—great constraint. Add `domain` + `deliverables` so downstream routing is deterministic.

---

# 2) Work-stream planner (parallelism without foot-guns)

* Build a **dependency graph** from the plan (shared files = edges).
* Partition into **independent components** → your parallel work-streams.
* Apply **file locks** on shared modules and cap concurrency (e.g., 3–6) to avoid racey writes.
* Each work-stream runs end-to-end: route → synthesize → verify → guard → export.

---

# 3) Domain router (one entry, N sub-pipelines)

Map `domain` to a **specialized lane**:

| Domain                   | Lane actions (machine-only)                                                                            | Exit condition                |
| ------------------------ | ------------------------------------------------------------------------------------------------------ | ----------------------------- |
| `python-script`          | Proven-process synthesis → static checks (Ruff, mypy optional) → unit smoke → runtime probe            | `verification.ok == true`     |
| `powershell-script`      | Proven synthesis → PSScriptAnalyzer → Pester smoke → runtime probe                                     | `verification.ok == true`     |
| `workflow` (CI YAML)     | Synthesize (GitHub Actions, etc.) → schema lint (actionlint / JSON/YAML schema) → dry-run if available | `schema_ok && dry_run_ok`     |
| `config` (pyproject, PS) | Schema/semantic validation (toml/yaml/json), consistency checks, idempotency checks                    | `schema_ok && consistency_ok` |
| `docs`                   | Link/anchor checks, required sections policy                                                           | `docs_policy_ok`              |

> Your note “workflow files don’t need domain-specific error detection; scripts do” is directionally right—**do validate workflows** with schema/action linters even if you don’t execute them.

---

# 4) Deliverables-first synthesis (the brain of the system)

* Treat each `deliverable` as an **acceptance contract** (e.g., “watch:lint:test”).
* For each deliverable, call the **Proven-Process Discovery Pipeline** you built earlier to select a **champion method** (e.g., *Invoke + watchfiles + ruff + pytest*).
* Fill deterministic **templates** to **create or edit** files.
* If editing, use **structured patching** (AST for Python/PowerShell; TOML/YAML merge for configs) rather than raw text diffs to reduce churn.

**synthesis_out.json**

```json
{"workstream_uid":"WS-001","ops":[
  {"path":"tasks.py","op":"create","synth_source":"invoke_watchfiles_v1","hash":"..."},
  {"path":"pyproject.toml","op":"edit","patch":"TOML-MERGE","hash":"..."}
]}
```

---

# 5) Guardrails & templates (keep the repo coherent)

* **Structure guards**: enforce your modular layout (Two-ID naming, folders, layering).
* **Style guards**: formatters (Black/Ruff for py, PSSA -Fix for PS, Prettier/yamllint).
* **Policy guards**: license headers, no secrets, allowed imports, size limits.
* **Schema guards**: JSON/YAML/TOML schema checks for configs and workflows.

All guardrail results are machine logs (no prose), appended to a **ledger.jsonl** with ULIDs.

---

# 6) Verification & error loop (bounded, auto-repair first)

**For scripts**

1. **Static phase**: Ruff/PSSA; attempt **auto-fix** once.
2. **Unit smoke**: quickest subset (`pytest -q -k smoke`, minimal Pester); time-boxed.
3. **Runtime probe**: run the deliverable entrypoint with a 5–10s timeout (e.g., start watcher, confirm startup banners, then stop).

**For workflows/config**

* Validate **schema** + **dry-run** if supported.

**If failing**

* Try **deterministic repair passes** (format/organize imports/fix easy rules).
* If still failing: emit **compact machine error report** with fingerprints (rule IDs, line ranges) and **stop** the stream (no flapping).
* Your final outputs remain: *error-free artifacts* or *a small machine error bundle* for escalation.

---

# 7) Export & integration (one human-facing artifact)

Per work-stream:

* **Change bundle**: atomic patch set (git diff/patch), new/edited files with hashes.
* **Minimal commit/PR metadata** (machine generated, but readable):

  * Title: `WS-001: Add watch+lint+test pipeline (Invoke)`
  * Body: bullet list of ops + deliverables + verification matrix summary.
* **Ledger update**: append ULIDs for synthesis, guardrails, verification.

> Humans only need to review the **final patch or file** if anything.

---

# 8) Safety, provenance, and rollbacks

* **Provenance tags**: each generated file carries a short header block with template id + source ULIDs (not prose).
* **Staging branch per work-stream**; optionally a **merge-train** to land them in sequence after CI green.
* **Auto-revert** on post-merge regressions (guard by your existing gates).

---

# 9) Performance & concurrency notes

* **Dedupe discovery**: if two work-streams ask for the same deliverable (e.g., `watch:lint:test`), reuse the same champion method and synthesis assets.
* **Resource caps**: limit parallel verifications to avoid thrashing (especially venv spins).
* **Warm caches**: pre-create venvs/tool caches keyed by tool version to shrink cold starts.

---

# 10) Edge cases to design for

* **Cross-file edits**: changing `pyproject.toml` plus `tasks.py`—order with a local topo sort and validate after each edit.
* **Line endings/encodings** across OSes.
* **Shell differences** (PowerShell vs POSIX quoting); prefer library calls (Invoke run options) over raw shell strings.
* **Secrets** in configs: enforce redaction and block on accidental insertion.

---

# 11) Minimal artifact set (keep it tiny)

```
/.out/
  champion/                # final files per work-stream (what humans see)
  bundle.patch             # optional atomic patch
/._machine/
  ledger.jsonl             # append-only facts (ULIDs, hashes, pass/fail)
  plans/                   # proposed_change_plan.json (original + normalized)
  synthesis/               # small JSON manifests (no prose)
  verify/                  # concise results, logs pointers
```

---

# 12) “First slice” implementation order

1. **Normalize plan → work-streams** (graph partition + locks)
2. **Domain router** (python-script, powershell-script, workflow, config)
3. **Synthesis templates** (2–3 high-value templates to start)
4. **Guardrails** (format + schema)
5. **Verification** (static + smoke + probe)
6. **Exporter + ledger**
7. **Parallelism & caching** (optimize later)

---

## Verdict

Your workflow is the right backbone. With the additions above—formal change plans, a domain router, deliverables-as-tests, bounded auto-repair, and atomic export—you’ll get **AI-operated, low-risk, parallel code changes** that are provably aligned with **proven methods**, end in **error-free, modular scripts**, and surface only the **final artifact** to humans.



Here you go—one-liners for each module in the AI-operated pipeline:

* **Plan Ingestor** — Parses `proposed_change_plan.json` and normalizes ops (edit/create/remove) with domains and deliverables.
* **Work-Stream Planner** — Builds a dependency graph, partitions independent work-streams, and applies file locks for safe parallelism.
* **Domain Router** — Routes each op to the correct lane (python-script, powershell-script, workflow, config, docs).
* **Goal Normalizer** — Converts high-level goals into capability tags and constraints for deterministic search.
* **Query Expander** — Produces stable `queries.yaml` by combining capability synonyms with ecosystem/platform anchors.
* **Discovery Adapters** — Collects candidate solutions from code hosts, registries, and docs into append-only `evidence.jsonl`.
* **Feature Extractors** — Normalizes signals (license, releases, examples, tests, CI, OS fit) into structured `features.jsonl`.
* **Scorer** — Computes the Provenness Score using tunable weights and policy gates (license/maintenance windows).
* **Synthesizer** — Generates new files or edits via capability→template mappings to satisfy deliverables.
* **Structured Patcher** — Applies safe edits using AST/TOML/YAML merges instead of brittle text diffs.
* **Guardrails** — Enforces structure, style, policy, and schema checks to keep outputs modular and compliant.
* **Verifier** — Runs static checks, smoke tests, and time-boxed runtime probes in disposable envs/containers.
* **Selector** — Chooses the highest-scoring candidate that passes verification; falls back or spikes if needed.
* **Exporter** — Emits the single champion artifact (file/patch) and minimal PR metadata for human review.
* **Ledger** — Records all steps as append-only JSONL (ULIDs, hashes, sources, pass/fail) for provenance.
* **Policy Pack** — Centralizes license allowlists, maintenance windows, OS matrix, and scoring profiles.
* **Caching & Rate-Limiter** — Mirrors raw API payloads, dedupes queries, and respects rate limits/backoff.
* **Concurrency Controller** — Caps parallel jobs, manages work-queue fairness, and prevents resource thrash.
* **Error Auto-Repair** — Applies deterministic fixes (formatters/organizers) before escalating failures.
* **Spike Harness** — Time-boxed sandbox trials to quickly validate borderline candidates or tie-breakers.
* **Provenance & Rollback Manager** — Embeds template/source ULIDs in files and supports automatic revert on regressions.
* **CI/Pre-Commit Integrator** — Wires gating rules into hooks and pipelines to block merges without fresh, verified outputs.
* **Playbook Promoter** — Elevates verified solutions into reusable internal “proven playbooks” for future runs.
* **Observability** — Exposes minimal metrics/logs (run times, pass rates, cache hits) for health and tuning.
* **Knowledge Reuse Manager** — Reuses selected champions across work-streams to avoid duplicate synthesis.
