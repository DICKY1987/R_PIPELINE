# Pipeline File Manifest & Development Order (Supplement)

**Scope:** This supplement lists every file (and folder) you need to implement the **File‑Watcher Error‑Check Pipeline** described in the main blueprint. Each item includes its purpose and the **recommended development order**. This is implementation‑agnostic (no code). Where relevant, it distinguishes between the two orchestration choices:
- **Option A (PowerShell‑first / SSOT = Invoke‑Build)**
- **Option B (Python‑first / SSOT = Invoke)**

> **SSOT = Single Source of Truth.** Only one runner owns the dependency graph; the other runner exposes language‑specific sub‑tasks.

---

## 0) Assumptions & Conventions
- Repository root is denoted as `/`.
- All paths are repo‑relative.
-
- **Core** items are mandatory; **Optional** items are recommended for robustness; **Advanced** are for future enhancements.
- Development is organized in **Phases 0–7**. Each file below lists the **Phase** when it should be created.

---

## 1) Top‑Level Repository Layout (Target State)
```
/               
├─ .github/workflows/                
│  ├─ ci.yml                         
│  └─ nightly.yml          (optional)
├─ .runs/                            
│  ├─ watch/                         
│  └─ ci/                            
├─ docs/                             
│  ├─ result.schema.json             
│  ├─ routing.policy.md              
│  ├─ quarantine.policy.md           
│  └─ metrics.readme.md              
├─ scripts/                          
│  ├─ hooks/                         
│  │  ├─ pre-commit.sample           
│  │  └─ pre-push.sample             
│  └─ notify.sample                  
├─ watcher/                          
│  ├─ Watcher.config.json            
│  ├─ Watcher.ignore                 
│  ├─ Watcher.readme.md              
│  ├─ Watcher.ps1          (Option A)
│  └─ Watcher.py           (Option B)
├─ build/                            
│  ├─ Build.readme.md                
│  ├─ Build.ps1            (Option A)
│  └─ tasks.py             (Option B)
├─ adapters/                         
│  ├─ PythonAdapter.psm1   (Option A)
│  ├─ PwshAdapter.psm1     (Option A)
│  ├─ python_tasks.py      (Option B)
│  └─ pwsh_tasks.py        (Option B)
├─ configs/                          
│  ├─ PSScriptAnalyzerSettings.psd1  
│  ├─ Pester.psd1                    
│  ├─ pyproject.toml                 
│  ├─ pyrightconfig.json  (or mypy.ini)
│  ├─ bandit.yaml         (optional)  
│  ├─ pre-commit-config.yaml (opt.)  
│  └─ tool-versions.lock   (optional)
├─ quarantine/                       
│  └─ README.md                      
├─ .editorconfig                      
├─ .gitattributes                     
├─ .gitignore                         
├─ AGENTS.md                          
├─ CLAUDE.md                          
├─ CONTRIBUTING.md                    
├─ LICENSE                            
└─ README.md                          
```

---

## 2) File‑by‑File Manifest (Purpose & Phase)

### 2.1 CI & Workflows
1. **`.github/workflows/ci.yml`** — Core — **Phase 3**  
   *Purpose:* CI parity: runs the same `ci` meta target as local; uploads artifacts (coverage/logs).  
   *Depends on:* Orchestrator SSOT, basic configs.

2. **`.github/workflows/nightly.yml`** — Optional — **Phase 6**  
   *Purpose:* Scheduled full sweep (all tests + security) independent of save events.

### 2.2 Ledger & Logs
3. **`/.runs/` (folder)** — Core — **Phase 1**  
   *Purpose:* Root for machine logs and artifacts.

4. **`/.runs/watch/`** — Core — **Phase 1**  
   *Purpose:* Per‑event results from the watcher (JSON + human logs).

5. **`/.runs/ci/`** — Core — **Phase 3**  
   *Purpose:* CI outputs: test reports, coverage, summaries.

### 2.3 Documentation & Policies
6. **`/docs/result.schema.json`** — Core — **Phase 1**  
   *Purpose:* Canonical schema for per‑file result records emitted by `check.one`.

7. **`/docs/routing.policy.md`** — Core — **Phase 1**  
   *Purpose:* Extension → toolchain mapping; test selection policy; escalation rules.

8. **`/docs/quarantine.policy.md`** — Optional — **Phase 4**  
   *Purpose:* When/how to quarantine files; how sidecars are created and cleared.

9. **`/docs/metrics.readme.md`** — Optional — **Phase 5**  
   *Purpose:* Defines the minimal metrics set and how to roll them up from the ledger.

### 2.4 Hooks & Notifications
10. **`/scripts/hooks/pre-commit.sample`** — Optional — **Phase 5**  
    *Purpose:* Example git hook to run fast format/lint subset on commit.

11. **`/scripts/hooks/pre-push.sample`** — Optional — **Phase 5**  
    *Purpose:* Example git hook to run `dev` or a reduced `ci` target before push.

12. **`/scripts/notify.sample`** — Optional — **Phase 4**  
    *Purpose:* Stub for local notifications (toast/CLI ticker) using the ledger outputs.

### 2.5 Watcher Layer (Front Door)
13. **`/watcher/Watcher.config.json`** — Core — **Phase 2**  
    *Purpose:* Include/exclude globs, debounce ms, stability windows, concurrency limits.

14. **`/watcher/Watcher.ignore`** — Core — **Phase 2**  
    *Purpose:* Ignore patterns (temp/swap/build outputs); editor‑specific noise.

15. **`/watcher/Watcher.readme.md`** — Optional — **Phase 2**  
    *Purpose:* Operator guide: what is watched, what gets ignored, and why.

16. **`/watcher/Watcher.ps1`** — Core (Option A) — **Phase 4**  
    *Purpose:* PowerShell file watcher entry that enqueues stabilized file paths and calls `check.one`.

17. **`/watcher/Watcher.py`** — Core (Option B) — **Phase 4**  
    *Purpose:* Python watchdog entry that enqueues stabilized file paths and calls `check.one`.

### 2.6 Orchestrator Layer (SSOT)
18. **`/build/Build.readme.md`** — Core — **Phase 2**  
    *Purpose:* Describes targets (`fix`, `lint`, `types`, `test`, `security`, `check.one`, `dev`, `ci`) and their contracts.

19. **`/build/Build.ps1`** — Core (Option A) — **Phase 3**  
    *Purpose:* **Invoke‑Build** task graph (SSOT): defines canonical targets; routes by extension; writes results.

20. **`/build/tasks.py`** — Core (Option B) — **Phase 3**  
    *Purpose:* **Invoke (pyinvoke)** task graph (SSOT): same responsibilities as above.

### 2.7 Tool Adapters Layer
21. **`/adapters/PythonAdapter.psm1`** — Core (Option A) — **Phase 3**  
    *Purpose:* Encapsulates Python tool calls (Ruff, Pyright/Mypy, Pytest, Bandit/pip‑audit) for PowerShell orchestrator.

22. **`/adapters/PwshAdapter.psm1`** — Core (Option A) — **Phase 3**  
    *Purpose:* Encapsulates PowerShell tool calls (Invoke‑Formatter, PSScriptAnalyzer, Pester) for PowerShell orchestrator.

23. **`/adapters/python_tasks.py`** — Core (Option B) — **Phase 3**  
    *Purpose:* Encapsulates Python‑side steps (format/lint/types/test/security) callable from `tasks.py`.

24. **`/adapters/pwsh_tasks.py`** — Core (Option B) — **Phase 3**  
    *Purpose:* Wraps PowerShell checks from Python (e.g., `pwsh -NoProfile -Command ...`) for consistency.

### 2.8 Language & Tool Configs (Config‑as‑Code)
25. **`/configs/pyproject.toml`** — Core — **Phase 2**  
    *Purpose:* Single source for Python formatting/linting (Ruff), pytest, and optional mypy settings.

26. **`/configs/pyrightconfig.json`** **or** **`/configs/mypy.ini`** — Core — **Phase 2**  
    *Purpose:* Type checker configuration (choose Pyright or Mypy; not both as SSOT).

27. **`/configs/bandit.yaml`** — Optional — **Phase 5**  
    *Purpose:* Security rules for Bandit (Python code scanning).

28. **`/configs/PSScriptAnalyzerSettings.psd1`** — Core — **Phase 2**  
    *Purpose:* PowerShell static analysis rules, severities, and exclusions.

29. **`/configs/Pester.psd1`** — Core — **Phase 2**  
    *Purpose:* Test discovery and output settings for PowerShell tests.

30. **`/configs/pre-commit-config.yaml`** — Optional — **Phase 5**  
    *Purpose:* Fast local checks on commit (format/lint subset) for Python; can trigger PowerShell formatters.

31. **`/configs/tool-versions.lock`** — Optional — **Phase 2**  
    *Purpose:* Records pinned versions of CLI tools/runners for reproducibility.

### 2.9 Quarantine & Sidecars
32. **`/quarantine/README.md`** — Optional — **Phase 4**  
    *Purpose:* Explains how quarantined files are handled and cleared.

33. **`<any‑file>.errors.md`** — Optional (generated) — **Phase 4**  
    *Purpose:* Sidecar summary for residual failures after auto‑fix + re‑lint.

### 2.10 Repo Hygiene & Metadata
34. **`/.editorconfig`** — Core — **Phase 1**  
    *Purpose:* Editor‑agnostic formatting defaults to reduce churn.

35. **`/.gitignore`** — Core — **Phase 1**  
    *Purpose:* Exclude `.runs/`, build artifacts, virtualenvs, caches.

36. **`/.gitattributes`** — Optional — **Phase 1**  
    *Purpose:* Normalize line endings; mark binary files; diff behaviors.

37. **`/AGENTS.md`** — Optional — **Phase 1**  
    *Purpose:* Instructions for AI/CLI agents (Codex/Claude) on which targets to run and how.

38. **`/CLAUDE.md`** — Optional — **Phase 1**  
    *Purpose:* Claude‑specific guidance aligned with repo tasks and policies.

39. **`/CONTRIBUTING.md`** — Core — **Phase 1**  
    *Purpose:* Developer obligations: “Run `dev` before push; `ci` in CI; what ‘pass’ means.”

40. **`/LICENSE`** — Core — **Phase 0**  
    *Purpose:* Repository licensing.

41. **`/README.md`** — Core — **Phase 0**  
    *Purpose:* Orientation; link to blueprint and this supplement.

---

## 3) Development Order (Phases & Deliverables)

### **Phase 0 — Initialize Repo Foundation**
- `LICENSE`  
- `README.md`

### **Phase 1 — Baseline Hygiene & Observability Shell**
- `.editorconfig`, `.gitignore`, `.gitattributes` (optional)  
- Create folders: `.runs/`, `.runs/watch/`, `.runs/ci/`, `docs/`, `configs/`, `scripts/hooks/`, `watcher/`, `build/`, `adapters/`, `quarantine/`  
- `docs/result.schema.json`  
- `docs/routing.policy.md`  
- `CONTRIBUTING.md`  
- `AGENTS.md` (optional), `CLAUDE.md` (optional)

### **Phase 2 — Configuration‑as‑Code (Tooling Contracts)**
- `configs/pyproject.toml`  
- `configs/pyrightconfig.json` **or** `configs/mypy.ini`  
- `configs/PSScriptAnalyzerSettings.psd1`  
- `configs/Pester.psd1`  
- `configs/Watcher.config.json`  
- `watcher/Watcher.ignore`  
- `build/Build.readme.md`  
- `configs/tool-versions.lock` (optional)

### **Phase 3 — Orchestrator (SSOT) & Adapters**
- **Option A:** `build/Build.ps1`, `adapters/PythonAdapter.psm1`, `adapters/PwshAdapter.psm1`  
- **Option B:** `build/tasks.py`, `adapters/python_tasks.py`, `adapters/pwsh_tasks.py`  
- `.github/workflows/ci.yml`  

### **Phase 4 — Watcher Integration & Quarantine Policy**
- **Option A:** `watcher/Watcher.ps1`  
- **Option B:** `watcher/Watcher.py`  
- `docs/quarantine.policy.md` (optional)  
- `quarantine/README.md`  
- `scripts/notify.sample` (optional)

### **Phase 5 — Developer Experience & Hooks**
- `configs/pre-commit-config.yaml` (optional)  
- `scripts/hooks/pre-commit.sample`  
- `scripts/hooks/pre-push.sample`  
- `docs/metrics.readme.md`  
- (Optional) simple metrics roll‑up script location noted in `docs/metrics.readme.md`.

### **Phase 6 — CI Enhancements & Schedules**
- `.github/workflows/nightly.yml` (optional)  
- Harden artifact upload/retention policies; ensure parity with local `ci`.

### **Phase 7 — Hardening & Advanced Ops**
- Policy refinements (routing/quarantine) and version pinning updates.  
- Add CODEOWNERS (optional) and SECURITY.md (optional) if relevant.  
- Expand watch roots or add multi‑repo support as needed.

---

## 4) Dependency Map (Highlights)
- **Watcher → Orchestrator:** Watcher requires the SSOT target `check.one` to exist.  
- **Orchestrator → Configs:** Orchestrator requires tool configs (`pyproject.toml`, `PSScriptAnalyzerSettings.psd1`, etc.) to be present.  
- **CI → Orchestrator:** CI runs `ci` meta target; needs SSOT in place.  
- **Adapters → Tools:** Adapters depend on the chosen toolchain (Ruff, Pyright/Mypy, PSScriptAnalyzer, Pester).  
- **Quarantine → Policy:** Quarantine behavior refers to `docs/quarantine.policy.md`.

---

## 5) Acceptance Checklists (Per Phase)

**Phase 1**  
- [ ] Folders created.  
- [ ] Schema and routing policy drafted.  
- [ ] CONTRIBUTING.md describes local vs CI parity.  

**Phase 2**  
- [ ] Lint/format/type/test configs exist and load.  
- [ ] Watcher config/ignore defined; paths validated.  

**Phase 3**  
- [ ] SSOT targets declared: `fix`, `lint`, `types`, `test`, `security`, `check.one`, `dev`, `ci`.  
- [ ] CI workflow can call `ci` and collect artifacts.  

**Phase 4**  
- [ ] On save, watcher calls `check.one` with a stabilized path; a result JSON appears in `.runs/watch/…`.  
- [ ] Quarantine sidecars appear for residual failures.  

**Phase 5**  
- [ ] Hooks run fast checks; do not exceed agreed latency budgets.  
- [ ] Metrics doc aligns with ledger schema.  

**Phase 6–7**  
- [ ] Nightly full sweep operational (if used).  
- [ ] Policies refined based on failure patterns; versions pinned.

---

## 6) File Ownership & Accountability (Suggested)
- **Orchestrator (SSOT):** Build/Dev Lead.  
- **Watcher:** Platform/Tooling Engineer.  
- **Python configs:** Python Lead.  
- **PowerShell configs:** PowerShell Lead.  
- **CI workflows:** DevOps/Platform.  
- **Docs & Policies:** Tech Writer/Lead.

---

## 7) Notes on Option Selection
- If Windows/.NET/PowerShell dominates: choose **Option A** and treat Python as a leaf via adapters.  
- If Python dominates or cross‑platform is primary: choose **Option B** and shell to PowerShell checks via adapters.  
- Avoid maintaining two DAGs; one SSOT prevents drift, speeds onboarding, and simplifies CI.

---

## 8) Future Extensions (File Stubs You Can Add Later)
- `tools/metrics/summarize_results.py` — roll‑up ledger to CSV/HTML.  
- `tools/dependency/impact_map.json` — map file → impacted tests for smarter selective runs.  
- `tools/ai/summarize_failures.md` — standard prompt to summarize frequent failure clusters.

---

### Final Remark
This manifest is a **complete checklist** to stand up the pipeline. Once you confirm **Option A** or **Option B**, proceed phase‑by‑phase and create only the files marked for that option. Keep this document versioned with the repo and update it as policies evolve.

