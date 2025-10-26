# File‑Watcher Error‑Check Pipeline Blueprint (Invoke‑Build + Invoke)

**Goal:** When any Python or PowerShell script is saved into designated folders, a local pipeline automatically (a) stabilizes the event, (b) formats and attempts safe auto‑fixes, (c) runs linters/types/tests/security checks, and (d) emits structured results for logs/dashboards. The same tasks run locally and in CI for perfect parity. **No code in this document—architecture and procedures only.**

---

## 1) Objectives & Non‑Goals

**Objectives**
- Instant feedback on save with a deterministic, repeatable pipeline.
- One command layer for both Python and PowerShell chores.
- Auto‑fix first, verify second; quarantine or sidecar errors that remain.
- Machine‑readable results written to an auditable ledger directory.
- CI/CD uses the same task targets to eliminate drift (local == CI).

**Non‑Goals**
- This blueprint does not provide implementation code.
- Not a replacement for full integration tests or deployment gates; it complements them.

---

## 2) Guiding Principles
- **Single Source of Truth (SSOT):** Keep the task graph owned by one runner (Invoke‑Build *or* Invoke). The other runner exposes language‑specific subtasks, not a parallel DAG.
- **Auto‑fix then lint:** Format and apply safe fixes first; then lint/type/test to reduce developer friction.
- **Small, fast loops:** Prefer file‑scoped checks on save; schedule periodic full sweeps.
- **Config‑as‑Code:** All tool settings live in repo configs (e.g., `pyproject.toml`, `PSScriptAnalyzerSettings.psd1`).
- **Structured Observability:** Every run writes compact JSON + human logs under a `.runs/` ledger.

---

## 3) High‑Level Architecture

**Layers**
1. **File‑Watcher Layer** (front door)
   - Watches designated folders, debounces noisy events, confirms file stability, and enqueues work.
2. **Orchestrator Layer** (task runner; choose one)
   - **Option A (PowerShell‑first):** Invoke‑Build owns the DAG and calls Python tools as needed.
   - **Option B (Python‑first):** Invoke (pyinvoke) owns the DAG and shells to PowerShell tools as needed.
3. **Tool Adapters Layer** (language‑specific)
   - Python: Ruff (format/lint/fix), Pyright/Mypy (types), Pytest (tests), pip‑audit/Bandit (security), packaging sanity checks.
   - PowerShell: Invoke‑Formatter, PSScriptAnalyzer (lint/fix), Pester (tests), module sanity checks.
4. **Reporting & Storage Layer**
   - JSON results, human logs, artifacts (e.g., coverage, test results) in `.runs/watch/…` and `.runs/ci/…`.

**Event Flow (save → results)**
Save → Debounce/Stable → Queue → Route by extension → **Fix** → **Lint** → **Types** → **Tests** → **Security** → Summarize → Persist results → Optional notify (toast/terminal/IDE).

---

## 4) Roles & Responsibilities

**File‑Watcher Layer**
- Observe file system events (**Created**, **Changed**, **Renamed**), include subfolders.
- Ignore temp/transient files (e.g., `~`, `.swp`, `.tmp`, `.part`, `.crdownload`).
- Debounce bursts per file; only enqueue latest stable version.
- Ensure stability: unchanged size for N ms and successful open for read.

**Orchestrator Layer** (choose one as SSOT)
- Exposes canonical targets (e.g., `fix`, `lint`, `types`, `test`, `security`, `check.one`).
- Routes a single file path to the correct toolchain based on extension.
- Ensures order: `fix` → `lint` → `types` → `test` → `security`.
- Aggregates exit state and emits uniform result records.

**Tool Adapters**
- Python: run format/fix; then ruff lint; types via pyright/mypy; selective tests via pytest `-k` for speed; optional full suite on schedule.
- PowerShell: Invoke‑Formatter; PSScriptAnalyzer with `-Fix` then strict; targeted Pester tests (file/module scope if practical).

**Reporting & Storage**
- Write one JSON result per processed file.
- Append a concise line to a rolling human log.
- Optional: maintain rolling metrics (counts, mean duration, failure rate) in a small summary JSON.

---

## 5) Decision: Which Runner Should Own the DAG?

**Choose Invoke‑Build (PowerShell) if:**
- Your repo is Windows/.NET/PowerShell heavy.
- You value built‑in incremental/persistent builds and simple graph views.

**Choose Invoke (pyinvoke) if:**
- Your repo is Python‑first or needs cross‑platform parity by default.
- You want Pythonic namespaces, hooks, and the ability to import the runner as a library.

**Hybrid rule:** Only one runner defines the official dependency graph. The other is called as a leaf step to avoid DAG drift.

---

## 6) Watcher Behavior (Detailed)

**Event Consolidation & Debounce**
- Maintain a per‑file timer (e.g., 300–800 ms) from the last change event.
- Each new event resets the timer; only after time elapses without change, enqueue.

**Stability Checks**
- Poll file size and attempt read access; proceed when two consecutive polls match and read succeeds.
- Drop events that stay unstable beyond a max wait window (record as `status: unstable_timeout`).

**Deduplication**
- Coalesce bursts; enqueue at most one work item per file in flight.
- If the file saves again while queued/running, mark the existing item as superseded—only latest is processed.

**Backpressure & Concurrency**
- Limit concurrent checks (e.g., 2–4 workers), queue the rest.
- Per‑path mutex: never process the same file in parallel.

**Inclusion/Exclusion**
- Include patterns: `**/*.py`, `**/*.ps1`, `**/*.psm1`, `**/*.psd1` (config updates may trigger broader checks).
- Exclude build outputs, virtual envs, `node_modules`, `.git`, `.runs`, `__pycache__`, etc.

---

## 7) Canonical Targets & Responsibilities (No Code)

**`fix` (idempotent) — Fast auto‑repair**
- Python: `format` then `check --fix` on the changed file/module.
- PowerShell: `Invoke‑Formatter` then PSScriptAnalyzer with `-Fix` for safe rules.

**`lint` — Strict/static analysis**
- Python: ruff (no fix), optional pylint/flake‑compat via ruff rules.
- PowerShell: PSScriptAnalyzer (no fix) with repo ruleset; fail on error‑level severities.

**`types` — Optional type safety**
- Python: pyright or mypy (file/module scope when possible for speed).

**`test` — Targeted tests for speed**
- Python: `pytest -k` pattern derived from changed file (module/test mapping policy).
- PowerShell: `Invoke‑Pester` for the nearest tests (file/module scope), CI runs full suite.

**`security` — Lightweight static safety**
- Python: pip‑audit (env), Bandit (code), basic dependency checks.
- PowerShell: curated script rules or third‑party scanners as policy allows.

**`check.one --path <file>` — The watcher entry**
- Runs: `fix` → `lint` → `types` → `test` → `security` for exactly one path and returns a structured result.

**`dev` / `ci` — Meta targets**
- `dev`: local loop (format/fix + lint + tests) on the current tree; fast defaults.
- `ci`: non‑interactive strict gate with artifacts/coverage, invoked by CI.

---

## 8) Routing Rules (Extension → Toolchain)

**Python (`.py`)**
- Apply Python toolchain; attempt module‑scoped tests; optionally trigger dependent tests via a simple mapping (e.g., package path).

**PowerShell (`.ps1`, `.psm1`)**
- Apply PowerShell toolchain; prefer nearby test discovery (e.g., `Tests/` next to module); validate manifests when relevant.

**Config Changes (`pyproject.toml`, `PSScriptAnalyzerSettings.psd1`)**
- Treat as *broad impact* signals: schedule a follow‑up batch run or mark the next `dev`/`ci` invocation to re‑validate more widely.

---

## 9) Result Artifacts & Ledger

**Locations**
- **Per run**: `.runs/watch/YYYY‑MM‑DD/HHMMSS_<ulid>/result.json`
- **Human log**: `.runs/watch/watch.log` (append‑only, line‑oriented)
- **CI logs**: `.runs/ci/...` mirroring structure

**Result Record (illustrative schema)**
- `timestamp` (ISO8601)
- `file_path` (repo‑relative)
- `language` (`python` | `powershell`)
- `steps` (array): each with `name`, `status` (`ok`|`changed`|`fail`|`skipped`), `duration_ms`, `messages[]`
- `fixes_applied` (bool; optional details per tool)
- `errors[]` (normalized code, message, line/col, tool)
- `exit_status` (`pass`|`fail`|`quarantine`|`unstable_timeout`)
- `superseded_by_newer_save` (bool)

**Quarantine & Sidecars**
- If auto‑fix fails to produce a clean `lint/types/test`, mark `exit_status: quarantine` and create a sidecar note (e.g., `<file>.errors.md`) summarizing the blockers.

---

## 10) Configuration‑as‑Code (Required Files)

**Python**
- `pyproject.toml` → Ruff config (format + lint), pytest, mypy/pyright settings.
- Optional: `bandit` config; `pre‑commit` hooks.

**PowerShell**
- `PSScriptAnalyzerSettings.psd1` → rules, severities, exclusions.
- `Pester.psd1` (or equivalent) → discovery, output formats.
- Optional: module manifests (`.psd1`) with `Test‑ModuleManifest` expectations.

**Repository Docs**
- `CONTRIBUTING.md` → how to run `dev`/`ci`, expectations before pushing.
- `CLAUDE.md` / `AGENTS.md` → tell AI/CLI agents which tasks to call for build, test, and release.

---

## 11) Integration with Git & CI

**Git Hooks (optional but recommended)**
- `pre‑commit`: fast format/fix subset (Ruff format + basic ruff rules; Invoke‑Formatter).
- `pre‑push`: run `dev` meta target or a reduced `ci` subset to block obvious failures.

**CI/CD**
- CI invokes the same `ci` target. Artifacts (coverage, reports) land in `.runs/ci/…` and are uploaded by the CI job.
- Nightly or scheduled full sweeps (all tests, full security scan) to catch cross‑file issues not triggered by save‑events.

---

## 12) Performance & Reliability Budgets

- **Debounce window:** 300–800 ms (tune per editor/FS behavior).
- **Max stabilization wait:** 5–10 s; then record `unstable_timeout` and skip.
- **Concurrency:** 2–4 workers; per‑file mutex.
- **Fast path SLO:** single‑file save → results in ≤ 3–8 s for typical modules.
- **Fail‑safe:** If the orchestrator is busy or down, buffer up to N items; drop beyond capacity with a log note.

---

## 13) Observability & Dashboards

- **Metrics to capture:**
  - Runs per hour/day; average/percentile durations.
  - Auto‑fix success rate; residual error rate by tool.
  - Top failing rules (ruff, PSScriptAnalyzer) to guide rule tuning.
- **Surfaces:**
  - Local: summarized console notifications or editor toasts.
  - Team: a lightweight HTML/markdown summary regenerated from the `.runs/` ledger; optional import into a dashboard.

---

## 14) Risk Management & Troubleshooting

- **Churny files (temp/swap):** Expand ignore patterns; extend debounce window.
- **Case‑sensitive paths on mixed OS:** Normalize repo‑relative paths; prefer canonical casing in logs.
- **Long‑running tests hamper save loop:** Restrict on‑save tests to file/module scope; run full suite on pre‑push/CI.
- **Tool version drift:** Pin tool versions and document upgrades; treat config changes as broad impact signals.
- **False positives:** Downgrade or disable rules in config after team review; keep strict in CI if necessary.

---

## 15) Rollout Plan (Phased)

**Phase 0 — Planning**
- Select SSOT runner (Invoke‑Build or Invoke).
- Finalize target names and result schema.
- Identify designated watch folders and exclude lists.

**Phase 1 — Local Pilot**
- Enable watcher on a small subset of folders.
- Validate `fix → lint → types → test → security` flow for a dozen files.
- Inspect `.runs/` outputs; tune debounce and ignore rules.

**Phase 2 — Team Adoption**
- Expand watch to the full code tree.
- Add `pre‑commit` and `pre‑push` optional hooks.
- Document in `CONTRIBUTING.md`; announce in team channels.

**Phase 3 — CI Parity**
- Wire CI to run the same `ci` meta target.
- Upload artifacts, publish dashboards.
- Add nightly full sweep.

**Phase 4 — Hardening**
- Add quarantine workflow; sidecar notes; optional auto‑PRs for formatting‑only changes.
- Establish SLOs and alerting thresholds for local/CI failure rates.

---

## 16) Policy Add‑Ons (Optional)

- **Change Detection Strategy integration:** For high‑impact changes (config, shared libs), trigger broader validations beyond the single file.
- **Security posture:** Adopt secret‑scanning and baseline policies; block high‑severity findings in `ci`.
- **Ownership & Codeowners:** Map watched paths to owners; mention owners in sidecar notes for faster triage.

---

## 17) Quick Checklists

**Day‑0: Setup**
- [ ] Pick SSOT runner (Invoke‑Build or Invoke).
- [ ] Define canonical targets and result schema.
- [ ] Identify watch roots, include/exclude patterns, debounce values.
- [ ] Commit config files (`pyproject.toml`, `PSScriptAnalyzerSettings.psd1`, `Pester.psd1`).
- [ ] Create `.runs/` structure in repo; decide retention policy.
- [ ] Document usage in `CONTRIBUTING.md`; add `CLAUDE.md` / `AGENTS.md` instructions for AI/CLI agents.

**Day‑1: Operate**
- [ ] Watcher running; verify events appear in `.runs/watch/watch.log`.
- [ ] On save, confirm a JSON result appears for the file.
- [ ] Validate auto‑fix → re‑lint loop; check that remaining failures are quarantined/annotated.
- [ ] Run `dev` locally; run `ci` in CI; compare outputs.
- [ ] Review metrics summary weekly; tune rules and thresholds.

---

## 18) Choosing Between Options (Summary Matrix)

| Criterion | Invoke‑Build (PowerShell) | Invoke (Python) |
|---|---|---|
| Primary ecosystem | PowerShell/.NET/Windows | Python/cross‑platform |
| Incremental/resume | Built‑in | Manual patterns |
| Graph visualization | Supported | Not built‑in |
| Library embedding | PowerShell module style | Native Python importable |
| Team skill set | PowerShell‑leaning | Python‑leaning |

**Recommendation:** If your stack is mixed but Windows‑leaning, choose **Invoke‑Build** as SSOT and call Python tasks within it. If Python‑first, invert that choice.

---

## 19) Roadmap & Future Enhancements

- Results exporter to CSV/HTML for leadership review.
- Lightweight tray/UI to surface failures and open sidecar notes.
- Dependency‑aware selective testing (e.g., run impacted tests based on import graph).
- Pre‑commit policy packs per folder (stricter rules in critical areas).
- Optional AI assist: summarize failure clusters from the ledger and propose rule tweaks.

---

### Final Note
This blueprint is implementation‑agnostic. Once you confirm the SSOT runner and exact tool choices (Ruff vs. Black, Pyright vs. Mypy, specific PSScriptAnalyzer rules), the next step is to codify these targets and watcher settings according to this plan. The payoff is a fast, self‑documenting, and developer‑friendly feedback loop that catches issues at the moment of change.

