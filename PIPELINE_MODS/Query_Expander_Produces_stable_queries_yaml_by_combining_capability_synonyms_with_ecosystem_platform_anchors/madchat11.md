Awesome goal. Here’s a **drop-in research gate** you can bolt onto every project so you automatically search for proven approaches **before** writing bespoke scripts.

# 1) What this adds to your dev flow

A standardized, zero-guesswork step that:

1. **Expands your problem into search queries**
2. **Scans GitHub, docs, blogs, and package registries**
3. **Scores candidates** (maturity, maintenance, popularity, licensing, examples, tests, CI)
4. **Emits evidence + a decision memo**
5. **Gates coding** until a pass/fail threshold is met (so you reuse first, build second)

# 2) High-level architecture (portable: Python or PowerShell)

* **Research Orchestrator** (CLI task): runs the whole pipeline (local or CI)
* **Query Builder**: turns your 1-line “need” into a set of expanded queries
* **Fetchers**:

  * GitHub (repos, stars, last commit, issues, license, README, examples/)
  * Code & Topic Search (GitHub code search, docs sites, official guides)
  * Package registries (PyPI/Conda/npm/Chocolatey as relevant)
* **Analyzers**:

  * Heuristics (examples/, tests/, CI badge, typed config, semver, changelog)
  * Health/Activity (recent releases, issue closure rate, bus-factor proxy)
  * Security (license allowlist, known CVE/audit hooks if package)
* **Ranker**: deterministic score and rank + guardrails
* **Reporters**:

  * `decision.md` (human-readable)
  * `evidence.jsonl` (machine trace)
  * `summary.md` (executive one-pager)
* **Gatekeepers**:

  * **pre-commit hook**: blocks coding if no decision file or score below threshold
  * **CI job**: blocks PRs if the research report is stale or missing

# 3) Standard repo layout (add this to *every* project)

```
.research/
  research.config.yaml         # inputs & knobs for this project
  queries.yaml                 # canonical query set (frozen for reproducibility)
  evidence.jsonl               # raw items (append-only ledger)
  ranked_candidates.json       # top N with normalized scores
  decision.md                  # pass/fail + rationale, links, chosen approach
  summary.md                   # concise 1-pager for reviewers
  cache/                       # raw API payloads (for idempotency)
  schema/                      # JSON Schemas for validation (below)
```

# 4) Deterministic scoring (tune once, reuse forever)

**Proven Approach Score (0–100)** — default weights:

* **Maintenance (25)**: last commit recency, release cadence, CI passing
* **Adoption (20)**: stars (log-scaled), forks, dependent count (if available)
* **Docs & Examples (20)**: README quality, `/examples|docs/examples|sample/` presence, runnable tasks
* **Test Coverage Signals (15)**: tests folder exists, CI badge present/green
* **License & Governance (10)**: OSI-approved license, clear maintainer(s), contributing guide
* **Domain Fit (10)**: keyword match quality & API shape fit to your problem

**Pass gate** (defaults you can change):

* **Use existing** iff a candidate ≥ **70** and license ∈ allowlist
* **Build custom** iff no candidate ≥ **60** after 2 search rounds
* Else **spike** (time-boxed eval of the top 1–2)

# 5) Minimal, reusable config (edit per project)

`./.research/research.config.yaml`

```yaml
problem: "File-watcher-driven error checking for Python & PowerShell scripts"
ecosystem: ["python", "powershell", "windows", "linux"]
must_have:
  - "runnable examples"
  - "active maintenance in last 12 months"
  - "permissive or weak-copyleft license"
nice_to_have:
  - "typed configuration"
  - "Invoke or Invoke-Build tasks"
search:
  languages: ["Python", "PowerShell"]
  exclude_words: ["toy", "student project"]
sources:
  - github_repos
  - github_code
  - official_docs
  - package_registries
scoring_profile: "default_v1"
allow_licenses: ["MIT","BSD-2-Clause","BSD-3-Clause","Apache-2.0","MPL-2.0"]
min_pass_score: 70
min_spike_score: 60
max_candidates: 50
```

# 6) JSON Schemas (keep your outputs strict & machine-parsable)

**evidence.jsonl (one JSON object per line)**

```json
{
  "atom_uid": "ulid-2025-10-26-01",
  "source": "github_repos",
  "repo": "owner/name",
  "url": "https://github.com/owner/name",
  "license": "Apache-2.0",
  "stars": 1834,
  "last_commit": "2025-09-15",
  "has_examples": true,
  "has_tests": true,
  "ci_status": "passing",
  "match_reasons": ["examples/", "mentions 'file watcher'", "invoke tasks"],
  "raw_refs": ["cache/owner_name_repo_meta.json"],
  "scorecard": {
    "maintenance": 22,
    "adoption": 15,
    "docs_examples": 18,
    "tests": 12,
    "license_governance": 9,
    "domain_fit": 8,
    "total": 84
  },
  "timestamp": "2025-10-26T01:00:00-05:00"
}
```

**ranked_candidates.json**

```json
{
  "problem": "File-watcher-driven error checking for Python & PowerShell scripts",
  "generated_at": "2025-10-26T01:00:00-05:00",
  "candidates": [
    {
      "repo": "owner/name",
      "score": 84,
      "url": "https://github.com/owner/name",
      "why": ["Proven examples", "Active releases", "MIT license"]
    }
  ]
}
```

# 7) Repeatable command surface (choose Python *or* PowerShell)

### Option A — Python (Invoke task runner)

* `inv research.init` → create `.research/*` scaffolding & default config
* `inv research.run` → build queries, fetch, analyze, rank
* `inv research.report` → write `decision.md` + `summary.md`
* `inv research.refresh --force` → bust cache & rerun
* `inv research.verify` → validate JSON against schema + staleness checks

**Plumbing (under the hood):**

* GitHub: `gh api` for REST/GraphQL; or PyGithub if you prefer a lib
* Websites/docs: `requests` + `readme/Docs` fetch & simple heuristics
* Registries: PyPI JSON API, Chocolatey, etc. as applicable
* All raw API replies mirrored to `.research/cache/` for idempotency

### Option B — PowerShell (Invoke-Build)

* `Invoke-Build ResearchInit`
* `Invoke-Build ResearchRun`
* `Invoke-Build ResearchReport`
* `Invoke-Build ResearchVerify`

**Plumbing:**

* `gh api` via `Start-Process`/`Invoke-RestMethod`
* YAML via `ConvertFrom-Yaml` (PowerShell 7), JSON natively
* Same cache + schema validation pattern

# 8) The gate: block coding until research is done

* **pre-commit hook**: require fresh `.research/decision.md` and `.research/ranked_candidates.json` dated **after** the last change to `/tasks.py`, `/build.ps1`, or any new feature folder.
* **CI**: a `research-guard` job that fails if:

  * Evidence is older than N days
  * No pass/fail decision recorded
  * Chosen “custom build” without a spike rationale

# 9) Deterministic query expansion (no AI dependency required)

* Start from `research.config.yaml.problem`
* Expand with static combinators:

  * `{file watcher, filewatch, directory monitor, chokidar, watchdog} × {lint, test, ruff, pester, pytest} × {invoke, invoke-build, task runner}`
* Persist the final list to `queries.yaml` so results are reproducible across machines/CI.

# 10) Evidence you actually read the repos

For each high-scoring repo, automatically collect:

* README headings (and presence of “Quickstart”, “Examples”, “Configuration”, “License”)
* Directory hits: `examples/`, `docs/examples/`, `sample/`, `tasks.py`, `*.yml` CI files
* Signals: `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `CHANGELOG*`, `pyproject.toml`
* Last 30 issues: open/closed ratio and MTTR approximation

# 11) Optional “security & supportability” checks

* **License allowlist** (MIT/BSD/Apache/MPL by default)
* **Package audit** (if library, run `pip index versions`, `pip-audit` or `safety`; for PowerShell modules, check Gallery metadata)
* **Windows/Linux parity**: flag repos that are Unix-only or Windows-only

# 12) Minimal ops to wire this into *every* repo

1. Add `.research/` folder + config/templates (above).
2. Add **task runner** (Invoke or Invoke-Build) targets named `Research*`.
3. Add a **pre-commit** rule:

   * On touching `/src`, `/scripts`, or `/Modules`, run `research.run` (cached) + `research.verify`.
4. Add **CI job** `research-guard` in your primary workflow, runs on PRs.
5. Add a **PR template** checkbox: “I ran the research gate; decision attached.”
6. Teach your CLI (or Makefile) a single top-level command:

   * `make bootstrap` → includes `research.init` then exits with next steps.

# 13) Day-1 file checklist (to create now)

* `.research/research.config.yaml`
* `.research/queries.yaml` (auto-generated from config the first run)
* `.research/schema/evidence.schema.json` & `ranked_candidates.schema.json`
* Task runner file (`tasks.py` **or** `build.ps1`)
* `.pre-commit-config.yaml` (or `.githooks/pre-commit`)
* `/.github/workflows/research-guard.yml`
* `docs/RESEARCH_GATE.md` (explain process and pass thresholds)

# 14) Example guard rules (copy/paste into your policies)

* **Do not** author custom scripts until:

  * At least **one** candidate ≥ **70** is reviewed and explicitly rejected with rationale, **or**
  * No candidate ≥ **60** and a **time-boxed spike** is recorded
* All rejections must cite **objective criteria** (missing examples, stale project, incompatible license, etc.)

---

If you want, I can generate the **starter pack** (folder scaffold, YAML templates, JSON Schemas, pre-commit, CI job, and Invoke/Invoke-Build task stubs) exactly in your naming conventions (Two-ID, append-only ledgers, etc.) so you can drop it into any repo and be done in one move.
