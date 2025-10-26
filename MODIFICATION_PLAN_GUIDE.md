# Modification Plan Guide: Proven DevOps Patterns Integration

**Generated:** 2025-10-26
**Source Documents:**
- `evidence.jsonl` (35 proven patterns from 10+ repositories)
- `Proven DevOps Patterns for AI-Operated Pipeline.pdf` (35 pages of analysis)

**Plan File:** `modification_plan_proven_patterns.yaml`

---

## Executive Summary

This modification plan integrates **battle-tested DevOps patterns** from mature tools (Invoke-Build, GitHub Actions, Git, PyGithub, watchfiles, etc.) into the AI-Operated Pipeline. The plan is **machine-first**, using deterministic IDs and Git worktrees for safe, auditable execution.

### Key Statistics

| Metric | Value |
|--------|-------|
| **Total Phases** | 6 |
| **Total Workstreams** | 13 |
| **Timeline** | 3 weeks |
| **Patterns Integrated** | 35+ |
| **Estimated Effort** | 120 hours |

### Priority Distribution

- **Critical/High Priority:** Phases 1-3 (Foundation, Quality Gates, CI/CD)
- **Medium Priority:** Phases 4-5 (Registry, SafePatch)
- **Low Priority:** Phase 6 (Performance Optimization)

---

## Phase Overview

### Phase 1: Foundation Refactoring (Week 1)
**Priority:** Critical
**Workstreams:** 3

Implements core infrastructure improvements:

1. **Incremental Task Execution** (WS1.1)
   - Pattern: Invoke-Build `-Inputs`/`-Outputs`
   - Benefit: Skip validation of unchanged files (95% skip rate target)
   - Module: `Streamlined_Watcher (SW-1A0)`

2. **Asynchronous Event Handling** (WS1.2)
   - Pattern: PowerShell `Register-ObjectEvent`
   - Benefit: Zero lost file events during rapid saves
   - Module: `Streamlined_Watcher (SW-1A0)`

3. **Structured Logging** (WS1.3)
   - Pattern: Python logging + PowerShell ErrorRecord
   - Benefit: 100% schema-compliant logs for audit
   - Module: `Observability (OB-6W1)`

**Exit Criteria:**
- ✅ Watcher latency < 2s (p95)
- ✅ 95% of unchanged files skip re-validation
- ✅ 100% log schema compliance
- ✅ Zero event loss

### Phase 2: Quality Gates Automation (Week 1)
**Priority:** High
**Workstreams:** 2

Automates quality enforcement at commit time:

1. **Pre-Commit Hooks** (WS2.1)
   - Pattern: pre-commit framework
   - Tools: Black, Ruff, PSScriptAnalyzer
   - Module: `CI_PreCommit_Integrator (CI-6E2)`

2. **Conventional Commits Linting** (WS2.2)
   - Pattern: commitlint
   - Benefit: Enables automated changelog + SemVer
   - Module: `CI_PreCommit_Integrator (CI-6E2)`

**Exit Criteria:**
- ✅ 100% hook installation success
- ✅ 95% commit message compliance
- ✅ No false positives/negatives

### Phase 3: CI/CD Integration (Week 2)
**Priority:** High
**Workstreams:** 2

Optimizes GitHub Actions workflows:

1. **Reusable Workflows** (WS3.1)
   - Pattern: Composite actions
   - Benefit: Zero duplicated CI steps
   - Module: `CI_PreCommit_Integrator (CI-6E2)`

2. **Caching Strategy** (WS3.2)
   - Pattern: actions/cache with restore-keys
   - Benefit: 40% build time reduction (target)
   - Module: `Cache_RateLimit (CR-4Y8)`

**Exit Criteria:**
- ✅ 40% CI build time reduction
- ✅ Zero workflow duplication
- ✅ 80% cache hit rate

### Phase 4: Module Registry Enhancement (Week 2)
**Priority:** Medium
**Workstreams:** 2

Enriches module metadata:

1. **Registry Metadata** (WS4.1)
   - Pattern: PowerShell module manifests
   - Adds: version, owner, dependencies, last_updated
   - Module: `Module_Registry (REG-001)`

2. **Automated Versioning** (WS4.2)
   - Pattern: Conventional Commits → SemVer
   - Benefit: Auto-bump versions from commit messages
   - Module: `Module_Registry (REG-001)`

**Exit Criteria:**
- ✅ 100% module metadata coverage
- ✅ All versions tracked with SemVer

### Phase 5: SafePatch Integration (Week 3)
**Priority:** Medium
**Workstreams:** 1

Hardens SafePatch integration:

1. **Error Capture** (WS5.1)
   - Pattern: PowerShell structured error handling
   - Benefit: 100% error capture with context
   - Module: `Verifier (VR-8X4)`

**Exit Criteria:**
- ✅ 100% SafePatch errors captured
- ✅ All outputs schema-compliant

### Phase 6: Performance Optimization (Week 3)
**Priority:** Low
**Workstreams:** 1

Evaluates parallel execution:

1. **Parallel Evaluation** (WS6.1)
   - Pattern: Invoke-Build `-Parallel`
   - Benefit: Potential 1.5x speedup
   - Module: `Concurrency_Controller (CC-2Z5)`

**Exit Criteria:**
- ✅ Baseline metrics captured
- ✅ 1.5x speedup (if implemented)

---

## Pattern Coverage Map

| Pattern | Source | Workstream(s) |
|---------|--------|---------------|
| **Incremental Builds** | Invoke-Build, doit | WS1.1 |
| **Debounced File Watching** | watchfiles, Taskfile | WS1.2 |
| **Structured Logging** | Python logging, PS ErrorRecord | WS1.3 |
| **Git Hooks** | pre-commit, Git | WS2.1, WS2.2 |
| **Conventional Commits** | conventional-changelog | WS2.2, WS4.2 |
| **Composite Actions** | GitHub Actions | WS3.1 |
| **Caching Strategy** | actions/cache | WS3.2 |
| **Module Manifests** | PowerShell | WS4.1 |
| **Content-Addressable IDs** | Git | All (via MFIDs) |
| **Error Handling** | PowerShell, PyGithub | WS5.1 |
| **Parallel Execution** | Invoke-Build | WS6.1 |

---

## Machine-First Design

### Deterministic IDs

Every entity has **lineage** (stable across revisions) and **instance** (unique per run):

- **Phases:**
  - `phase_lineage_id`: `UUIDv5("phase:<phase_key>")`
  - `phase_instance_id`: `ULID()`

- **Workstreams:**
  - `wslid`: `UUIDv5("{phase_lineage_id}|{module_id}|{role}")`
  - `wsid`: `ULID()`

- **Files:**
  - `module_file_id`: `blake3(normalized_path + content)[:20]`

### Git Isolation

Each workstream gets:
- ✅ Dedicated branch: `{lane}/{phase_seq}-{phase_key}/{module_id}/{wsid}`
- ✅ Isolated worktree: `/tmp/worktrees/{wsid}`
- ✅ Path claims to prevent conflicts

### Provenance Tracking

Every action emits to `/.runs/ledger.jsonl`:

```json
{"t":"ws.create","wsid":"01J...","branch":"lane/1-foundation/SW-1A0/01J...","ok":true,"ms":210}
{"t":"ws.step","wsid":"01J...","step":"verify","ok":true,"ms":4210}
{"t":"ws.done","wsid":"01J...","status":"succeeded","ms":12890}
```

---

## Execution Workflow

### Pre-Schedule Validation

1. ✅ Schema validate `modification_plan.yaml`
2. ✅ Resolve path claims (deny overlaps)
3. ✅ Pin `module_file_id`s from `module_file_index.jsonl`
4. ✅ Write `ws.manifest.json` for each workstream

### Runtime Execution

For each workstream:

1. **Create worktree** → `git worktree add /tmp/worktrees/{wsid} -b {branch}`
2. **Run module** → Execute with pinned file IDs
3. **Validate** → Check against schemas
4. **Log** → Append to ledger
5. **Merge** → Enqueue if all checks pass
6. **Cleanup** → Remove worktree

### Post-Merge

- ✅ Auto-delete branch if `auto_delete_branch: true`
- ✅ Remove worktree if `auto_remove_on_complete: true`
- ✅ Update ID Authority with completion status

---

## Risk Mitigation

| Risk | Severity | Mitigation |
|------|----------|------------|
| **Duplicate file events** | Medium | 300ms debounce + stability check |
| **Async race conditions** | High | PowerShell mutex + single event handler |
| **Cache invalidation** | Medium | Content-based keys (BLAKE3 hashing) |
| **Hook bypass** | Medium | CI enforcement as backup |
| **Parallel races** | High | Only parallelize independent tasks + file locks |
| **SafePatch dependency** | Medium | Mock in tests; document contract |

---

## Integration with SPEC-1

This plan **complements** (not replaces) the existing SPEC-1 infrastructure:

| SPEC-1 Component | Integration Point |
|------------------|-------------------|
| **SafePatch** | Enhanced error capture (WS5.1) |
| **MCP Servers** | Not modified (out of scope) |
| **Policy/OPA** | Used for schema validation |
| **Audit Ledger** | Extended with workstream events |
| **Guardrails** | Enforced via pre-commit (WS2.1) |

---

## Success Metrics

### Phase 1 (Foundation)
- **Latency:** < 2s (p95) for file change → result
- **Cache Efficiency:** 95% skip rate for unchanged files
- **Event Reliability:** 0% event loss

### Phase 2 (Quality Gates)
- **Hook Adoption:** 100% installation success
- **Commit Compliance:** 95% conventional commits

### Phase 3 (CI/CD)
- **Build Speed:** 40% reduction via caching
- **Reuse:** 0 duplicated workflow steps

### Phase 4 (Registry)
- **Coverage:** 100% modules with metadata
- **Automation:** Auto-version bumping working

### Phase 5 (SafePatch)
- **Error Capture:** 100% with context
- **Schema Compliance:** 100%

### Phase 6 (Performance)
- **Speedup:** 1.5x (if parallel execution viable)

---

## Next Steps

1. **Review the plan:** `modification_plan_proven_patterns.yaml`
2. **Validate schemas:** Ensure all referenced schemas exist
3. **Prepare infrastructure:**
   - Create `/.runs/ledger.jsonl`
   - Set up ID Authority store
   - Initialize module file index
4. **Execute Phase 1:** Start with WS1.1 (Incremental Tasks)
5. **Monitor metrics:** Track exit criteria for each phase

---

## References

### Source Documents
- **evidence.jsonl**: 35 patterns from 10+ repositories
- **Proven DevOps Patterns PDF**: 35-page analysis with recommendations

### Key Repositories Analyzed
- `nightroman/Invoke-Build` (PowerShell task automation)
- `pyinvoke/invoke` (Python task automation)
- `pydoit/doit` (DAG-based build tool)
- `actions/*` (GitHub Actions official actions)
- `git/git` (Version control patterns)
- `PyGithub/PyGithub` (GitHub API client)
- `gorakhargosh/watchdog` (File system events)
- `samuelcolvin/watchfiles` (Rust-based file watcher)
- `PowerShell/PowerShell` (PowerShell engine)
- `tox-dev/tox` (Python testing automation)

### Template Used
- `agentic_modification_plan_machine_first_template_ai_usage_guide.md`

---

**Generated by AI Agent**
**Plan Version:** 2025.10.26+rev1
**Status:** Ready for execution
