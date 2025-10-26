Love this. Let’s design a **repeatable “Proven-Process Discovery Pipeline”** you can bolt onto any project so it *automatically* searches repos/sites/libs/tools for established approaches **before** you write custom code.

# North-star principles

* **Reuse before build.** Gate new code on evidence that no solid, maintained solution exists.
* **Deterministic & auditable.** Inputs → queries → evidence → decision memo, all logged in an append-only ledger (ULIDs, timestamps).
* **Config over code.** New problem domains mean editing YAML, not rewriting the pipeline.
* **Human-in-the-loop by exception.** Auto-rank, auto-draft decisions; escalate only on ambiguity or policy violations.

# End-to-end flow (6 stages)

1. **Capture the goal** → normalize to **capability tags** and constraints
2. **Query expansion** → generate precise, multi-source searches
3. **Discovery** → fetch candidates from GitHub/docs/registries/etc.
4. **Analysis & scoring** → compute a **Provenness Score** per candidate
5. **Spike harness (optional)** → sandbox quick trials of the top 1–3
6. **Decision & gating** → emit memo + artifacts; block coding if thresholds unmet

---

## 1) Inputs (what the pipeline consumes)

* **Goal brief**: one sentence plus constraints (OS, language, license, offline, GPU, etc.).
* **Capability tags** (controlled vocabulary): e.g., `file-watch`, `task-runner`, `lint`, `test-orchestrator`, `windows`, `python`, `powershell`.
* **Policy pack**: license allowlist/denylist, maintenance window (e.g., “active in last 12 months”), security posture, allowed vendors.
* **Scoring profile**: weights for maintenance, docs, tests, adoption, security, domain fit.

## 2) Query expansion (deterministic, no AI required)

* **Synonym sets** per capability:
  `file-watch` → {file watcher, directory monitor, watchdog, chokidar, fsnotify}
  `task-runner` → {invoke, doit, make, nox, tox, taskipy, poe, pypyr}
* **Combinators**: `{capabilities} × {language} × {platform} × {keywords like “examples”, “tasks.py”, “docs/examples”}`
* Persist the expanded list to `queries.yaml` for reproducibility.

## 3) Discovery adapters (plug-in architecture)

Add adapters you can enable/disable per project:

* **Code hosts**: GitHub/GitLab/Bitbucket (repos, code search, topics, license, stars, last commit, CI badges, issues/PRs)
* **Registries**: PyPI/Conda, npm, PowerShell Gallery, Chocolatey, Homebrew (versions, release cadence, download stats)
* **Docs sites**: official docs, READMEs, `docs/` trees, `examples/` directories
* **Patterns library** (internal): your curated “Proven Playbooks” (see below)
* **Q&A/knowledge** (optional): StackOverflow tags, blog posts by maintainers

> All raw payloads mirrored into a **cache/** folder so runs are idempotent and diffable.

## 4) Heuristics & signals (what “proven” looks like)

* **Maintenance**: last release date, commit recency, CI status, bus-factor proxy (maintainer count)
* **Adoption**: stars (log-scaled), forks, dependents/downloads (where available)
* **Docs & examples**: `examples/`, `docs/examples/`, runnable `tasks.py`, quickstart, configuration reference
* **Quality**: presence of tests, coverage badge, typed config/CLI flags, semantic versioning
* **Security/compliance**: license ∈ allowlist, CVE mentions, security.md present
* **Domain fit**: capability tag overlap, OS support, language and shell semantics
* **Ops readiness**: change log, contributor guide, governance, release notes

## 5) Provenness Score (tunable rubric)

Default weights (0–100 total):

* Maintenance **25**
* Docs & Examples **20**
* Adoption **20**
* Tests & CI **15**
* License & Governance **10**
* Domain Fit **10**

**Pass gates** (edit per repo):

* **Adopt** if any candidate ≥ **75** and policy-clean
* **Time-box spike** if top candidate in **60–74**
* **Build custom** only if no candidate ≥ **60** *after* two search rounds

## 6) Spike harness (quick, automated reality check)

For the top N candidates:

* **Provision**: ephemeral venv/container (Windows/Linux matrix if needed)
* **Scripted trials**: run 2–3 canonical tasks (e.g., “watch + lint”, “watch + test”)
* **Capture**: success/fail, perf timings, logs, OS compatibility notes
* **Artifacts**: `spike_report.md`, `trial_logs/`, exit codes—fold back into the decision

## 7) Decision artifacts (what gets written)

* `evidence.jsonl` (append-only ledger; one JSON per observation)
* `ranked_candidates.json` (normalized, top N)
* `decision.md` (rationale, links, tradeoffs, chosen path)
* `summary.md` (1-pager for PR reviewers)
* `proven_playbook.yaml` (if adopting: the reusable steps/config you’ll keep)

## 8) Gating it into your dev lifecycle

* **pre-commit hook**: block commits touching `/src` or `/scripts` unless `decision.md` is present & fresher than the change.
* **CI job (`research-guard`)**: fails PR when evidence is stale (e.g., >14 days), policy violation, or decision missing.
* **PR template**: checkbox “Research gate passed; decision attached.”

## 9) Knowledge retention: your “Proven Playbooks”

Create a repo or folder (e.g., `proven-playbooks/`) that stores finalized, reusable **implementation playbooks**:

* Each playbook = `proven_playbook.yaml` with **Capabilities**, **Chosen Tools**, **Minimal Config**, **Task Runner Wiring** (e.g., Invoke/Invoke-Build session names), **Gotchas**, **Monitoring**.
* Link back to the evidence lines (ULIDs) that justified the choice.
* Over time this becomes your internal **pattern library** (e.g., *watch-and-lint Python*, *auto-rerun PowerShell Pester*, *invoke-based release pipeline*).

## 10) File & directory scaffold (drop into any repo)

```
.research/
  research.config.yaml
  queries.yaml
  evidence.jsonl
  ranked_candidates.json
  decision.md
  summary.md
  cache/
  schema/
proven-playbooks/
  file-watch_lint_test.yaml
docs/RESEARCH_GATE.md
```

## 11) Example `research.config.yaml` (skeleton)

```yaml
goal: "Continuous error checking for Python & PowerShell on file save"
capabilities: [file-watch, lint, test-orchestrator, task-runner, windows, python, powershell]
policy:
  license_allow: [MIT, BSD-2-Clause, BSD-3-Clause, Apache-2.0, MPL-2.0]
  maintenance_window_months: 12
scoring_profile: default_v1
sources:
  - github_repos
  - github_code
  - registries
  - docs_sites
discovery:
  max_candidates: 80
  rounds: 2
spike:
  enabled: true
  max_candidates: 2
  os_matrix: [windows, linux]
gates:
  adopt_min_score: 75
  spike_min_score: 60
  evidence_ttl_days: 14
outputs:
  keep_playbook: true
```

## 12) Operational concerns (so it scales)

* **Reproducibility**: cache raw API replies; include `queries.yaml` in artifacts.
* **Rate limits**: backoff & token-bucket; support GitHub unauth + PAT modes.
* **Idempotency**: ULID per run; don’t overwrite prior evidence—**append**.
* **Observability**: structured logs; a small dashboard showing last 10 decisions, average score, most frequent chosen tools.
* **Extensibility**: each adapter is a simple interface (`search() → items`, `enrich() → signals`, `score() → numbers`).
* **Security**: sanitize URLs, never execute candidate code during discovery (sandbox only in spike stage).
* **Governance**: owners for the policy pack; weekly “promote to playbook” review.

## 13) Brainstorm: useful adapters & signals to add next

* **Compatibility probes**: auto-scan README for Windows/PowerShell examples or POSIX-only instructions.
* **Migration cost estimator**: simple rubric (APIs touched × lines changed × required dependencies).
* **Lock-in risk**: cloud/vendor-specific flags, proprietary dependencies.
* **Community health**: issue response median, maintainer “time to first response”.
* **Version drift**: alert when your chosen playbook falls >2 releases behind upstream.

## 14) How this plugs into *your* stack (Python & PowerShell friendly)

* **Task runner**: Invoke (`inv research.init/run/report/verify`) *or* Invoke-Build (`Invoke-Build Research*`).
* **Watch mode**: use `watchfiles`/`watchdog` (Python) or `Register-ObjectEvent` (PowerShell) to re-run the research when the **goal brief** or **capability tags** change (not on every file save).
* **Pre-commit**: enforce the gate, plus run your usual format/lint/tests.
* **CI**: add `research-guard.yml` to block merges without fresh decisions.

---

If you want, I can output a **starter bundle** right now—`/.research` scaffolding, sample policy pack, JSON Schemas for `evidence.jsonl` & `ranked_candidates.json`, a default scoring profile, and Invoke/Invoke-Build task stubs—so you can drop it into a repo and start making decisions on evidence instead of gut feel.
