Perfect—let’s reshape the pipeline to be **AI-operated, machine-first, and outcome-driven**. The only human-facing artifact is the **final, runnable script/workflow**; everything else is compact, machine-readable, and optimized for chaining with other automations.

# Machine-First Proven-Process Discovery & Synthesis Pipeline

## 0) Black-box contract

* **Input (machine)**: `goal.json` + optional `constraints.json`
* **Output (human-optional)**: a single **champion artifact** (script/workflow) + a tiny **machine ledger** for traceability
* **Side artifacts (machine)**: append-only JSONL evidence, scores, verification results (no prose docs)

---

## 1) Modules & interfaces (all pluggable)

1. **Goal Normalizer**

   * **In**: `goal.json` (user intent)
   * **Out**: `capabilities.json` (normalized tags: e.g., `file-watch`, `lint`, `pytest`, `windows`, `python`)
   * **Notes**: Deterministic synonym mapping; no LLM required.

2. **Query Expander**

   * **In**: `capabilities.json`, `constraints.json`
   * **Out**: `queries.yaml` (cartesian expansion of synonyms × ecosystems × “examples/docs/recipes” anchors)
   * **Gate**: Stable seeds; same input ⇒ same queries.

3. **Discovery Adapters** (enable/disable per run)

   * **Sources**: GitHub/GitLab (repos & code); registries (PyPI/Conda/PowerShell Gallery); official docs; curated **internal playbooks**.
   * **Out**: `evidence.jsonl` (append-only)
   * **Rule**: Mirror raw payloads into `cache/` for reproducibility.

4. **Feature Extractors**

   * **In**: `evidence.jsonl` items
   * **Signals**: license, last release, examples presence (`examples/`, `tasks.py`, `docs/examples`), tests/CI, OS support mentions, API shape hints.
   * **Out**: `features.jsonl` (links each candidate → normalized features)

5. **Scorer** (Provenness Score)

   * **Weights (default, tunable)**: Maintenance 25 · Docs/Examples 20 · Adoption 20 · Tests/CI 15 · License/Gov 10 · Domain-Fit 10
   * **In**: `features.jsonl`, policy pack (license allowlist, maintenance window)
   * **Out**: `scores.json` (top-N ranked with reasons machine-readably)

6. **Synthesizer (Script/Workflow Builder)**

   * **Input**: top-K candidates + **Capability→Template map**
   * **Mechanism**: deterministic templates + transforms (no prose), selecting the **lowest-complexity proven method** that meets constraints.
   * **Out**:

     * `out/champion.py` (e.g., Invoke tasks) **or** `out/champion.ps1` (Invoke-Build) **or** `out/champion.yml` (CI workflow)
     * `workflow.json` (language-agnostic graph of steps, env, triggers)

7. **Verifier (Sandbox Runner)**

   * **Runs**: champion artifact in a disposable venv/container; executes **minimal proving tasks** (e.g., “watch → lint”, “watch → test”).
   * **Out**: `verification.json` (pass/fail, timings, logs pointers)
   * **Policy**: No untrusted execution during discovery; execution only here, with timeouts & resource caps.

8. **Selector (Champion Picker)**

   * **Logic**: pick highest score that **passes verification**; else fallback to next; else trigger “spike loop” (time-boxed variant generation).
   * **Out**: `champion_manifest.json` (path, hash, provenance IDs)

9. **Exporter**

   * **Delivers**: the **single final artifact** (script/workflow) in `/out`, ready to run.
   * **Also emits** (machine only): `ledger.jsonl` (ULID, inputs, scores, chosen candidate, verification IDs).

10. **Orchestrator**

* **Entry points**: `run:init`, `run:discover`, `run:score`, `run:synthesize`, `run:verify`, `run:export`
* **Guarantees**: atomic steps, resumable state, append-only logs.

---

## 2) Minimal data contracts (schemas you can paste into your validator)

**goal.json (input)**

```json
{
  "goal": "Continuous error checking on file save for Python & PowerShell",
  "priority": ["reuse","simplicity","windows-first"],
  "target_language_pref": ["python","powershell"],
  "environment": {"os": ["windows","linux"]},
  "licensing": {"allow": ["MIT","BSD-2-Clause","BSD-3-Clause","Apache-2.0","MPL-2.0"]},
  "constraints": {"offline_ok": false, "no_admin_rights": true}
}
```

**evidence.jsonl (append-only; one per candidate)**

```json
{"uid":"01JC..","source":"github_repos","id":"owner/name",
 "signals":{"license":"Apache-2.0","stars":1834,"last_release":"2025-06-01",
 "has_examples":true,"has_tests":true,"ci":"passing","os":["windows","linux"]},
 "paths":["examples/","tasks.py","docs/examples"],
 "cache_refs":["cache/owner_name_repo.json"],"ts":"2025-10-26T07:06Z"}
```

**scores.json (normalized top-N)**

```json
{"candidates":[
  {"id":"owner/name","score":84,"reasons":["examples","active","license-ok"]},
  {"id":"other/tool","score":73,"reasons":["docs-ok","tests-ok"]}
]}
```

**workflow.json (language-agnostic plan)**

```json
{
  "triggers": [{"type":"file_watch","paths":["src/**"],"events":["create","modify"]}],
  "steps": [
    {"id":"lint_py","run":{"tool":"ruff","args":["check","."]},"if":{"lang":"python"}},
    {"id":"test_py","run":{"tool":"pytest","args":["-q"]},"if":{"lang":"python"}},
    {"id":"lint_ps","run":{"tool":"pwsh","args":["-File","./Scripts/PSScriptAnalyzer.ps1"]},"if":{"lang":"powershell"}},
    {"id":"test_ps","run":{"tool":"pwsh","args":["-File","./Scripts/RunPester.ps1"]},"if":{"lang":"powershell"}}
  ]
}
```

**verification.json (result)**

```json
{"champion":"out/champion.py","matrix":["windows","linux"],
 "results":[{"os":"windows","ok":true,"time_ms":4200},{"os":"linux","ok":true,"time_ms":3800}],
 "logs":["logs/win.txt","logs/lin.txt"]}
```

---

## 3) Decision logic (deterministic)

1. Rank by **Provenness Score** (policy pack configurable).
2. Generate candidate artifacts from the top-K (e.g., Invoke vs doit vs taskipy).
3. **Verify** in sandbox across required OS targets.
4. Pick first **verified** candidate; if none pass, auto-generate a **fallback** (simpler local script) and verify again.
5. **Export** the champion + ledger; stop.

---

## 4) Synthesis strategy (how the script is produced)

* Use **capability→template** mappings (no prose):

  * `file-watch+python` → `watchfiles` loop + task runner (Invoke/doit/poe)
  * `file-watch+powershell` → `Register-ObjectEvent` + Invoke-Build targets
  * `ci-pipeline` → GitHub Actions YAML with caching/strategy matrix
* Fill templates from `workflow.json` (pure data → code).
* Prefer the **fewest moving parts** that satisfy constraints (e.g., `poe` in `pyproject.toml` over a custom CLI when possible).
* Always emit **one** artifact path: `out/champion.*`.

---

## 5) Policy & safety (fully automated)

* **No execution during discovery**; only in the **Verifier** with CPU/IO caps & timeouts.
* **License gating** and **maintenance windows** enforced before synthesis.
* **Idempotency**: ULID for every run; cache busting via explicit `run:discover --refresh`.
* **Reproducibility**: same input → same `queries.yaml` → stable candidates → stable artifact.

---

## 6) Chaining with other automations

* Everything is **file-protocol** driven (JSON/JSONL/YAML) → trivial to feed/consume from other AI agents.
* The **ledger.jsonl** is the only “explanation” other systems need to audit lineage or rebuild.

---

## 7) Drop-in repo scaffold (tiny, AI-friendly)

```
.proven/
  policy.yaml                # weights, license rules, OS matrix
  synonyms.yaml              # capability→synonym sets
  adapters.yaml              # which discovery adapters to run
  cache/
out/
logs/
ledger.jsonl                 # append-only run ledger (tiny, machine)
```

---

## 8) Example end-to-end outcome (what the user sees)

* `out/champion.py` — an Invoke-based watcher+lint+test workflow (or the PowerShell/GitHub Actions equivalent), already verified.
* Optional one-liner summary in CLI output (“Selected: invoke+watchfiles; verified on win+linux in 8.0s”). No PDFs, no markdown reports.

---

## 9) Quality gates (machine-only)

* **Adopt** if score ≥ 75 and `verification.ok == true`.
* **Fallback build** if no candidate ≥ 60 verifies.
* **Re-run discovery** weekly or when `goal.json`, `constraints.json`, or `policy.yaml` change.

---

## 10) What you can implement first (smallest viable slice)

1. **Goal → Capabilities → Queries** (deterministic expansion)
2. **GitHub + PyPI adapters** (just stars, license, releases, examples)
3. **Fixed scoring profile**
4. **Two synthesis templates** (Invoke+watchfiles, Invoke-Build watcher)
5. **Verifier** (venv/container + 2 proving tasks)
6. **Exporter + ledger**

This design gives you an **AI-operable, self-contained pipeline** that ingests a goal, searches for proven approaches, **synthesizes a runnable script**, proves it in a sandbox, and exports a single artifact—ready for humans to run or for other automations to chain into.
