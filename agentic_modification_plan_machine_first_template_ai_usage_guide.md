# Agentic Modification Plan — Machine‑First Template & AI Usage Guide

> **Purpose**: A fully machine-first template and usage guide that lets an agent generate *modification plans* with deterministic IDs, Git worktrees, and exact file provenance — no human-readable docs required.

---

## 0) Concepts & IDs (minimal set)

- **module_id (MID)** — Stable ID per module/folder (e.g., `DR-5K9`).
- **module_file_id (MFID)** — Content-addressed ID per file (e.g., `blake3(path_norm + content)[:20]`).
- **workstream_lineage_id (WSLID)** — Deterministic identity for a *kind* of workstream (UUIDv5 over `phase_lineage_id | module_id | role`).
- **workstream_instance_id (WSID)** — Time-sortable instance ID per plan/run (ULID/UUIDv7).
- **phase_lineage_id / phase_instance_id** — Same pattern as workstreams, for phases.
- **ID Authority** — Append-only store that allocates WSIDs and records lineage→instance evolution.

> **Why both lineage + instance?** Lineage groups revisions of the same logical thing; instance pins an exact, auditable run.

---

## 1) Modification Plan Template (YAML)

Use this file as the single input artifact an agent produces when proposing a set of changes. Fields are machine-only; values in `{braces}` are *derivable*; `…` mean agent fills values.

```yaml
version: 1.0
plan:
  plan_instance_id: "{ULID()}"
  plan_lineage_id: "{UUIDv5(\"plan:<canonical-key>\")}"
  plan_version: "{YYYY.MM.DD}+rev{N}"
  created_at: "{iso8601}"

  # Deterministic naming for branches/worktrees
  branch_template: "{lane}/{phase_seq}-{phase_key}/{module_id}/{wsid}"
  worktree_path_template: "/tmp/worktrees/{wsid}"

  # Global defaults (can be overridden at workstream level)
  defaults:
    lifecycle:
      auto_remove_on_complete: true
      remove_on_fail: true
      prune_stale: true
    routing:
      queue_prefix: "q"
    constraints:
      max_parallel_per_module: 1
      deny_overlapping_path_claims: true

  merge_policy:
    target_branch: "main"
    checks:
      - name: "ci/test"
      - name: "ci/lint"
    strategy: "squash"   # squash|rebase|merge

phases:
  - phase_seq: 1
    phase_key: "streamlined_watcher"
    phase_lineage_id: "{UUIDv5(\"phase:streamlined_watcher\")}"
    phase_instance_id: "{ULID()}"
    timebox_weeks: 1

    exit_criteria:
      - id: "EC-1"
        metric_key: "watcher.latency_p95_ms"
        target: 2000
        description: "Watcher detects file saves with p95 latency < 2s"

    metrics:
      - key: "watcher.latency_p95_ms"
        target: 2000

    risks:
      - key: "fs-notify-dup"
        mitigation: "debounce 300ms"

workstreams:
  - wslid: "{UUIDv5(\"wslid:{phase_lineage_id}|{module_id}|{role}\")}"
    wsid: "{ULID()}"

    phase_ref:
      phase_seq: 1
      phase_instance_id: "{ref:phases[0].phase_instance_id}"

    module_ref:
      module_key: "Domain_Router"
      module_id: "DR-5K9"
      role: "run"           # run|verify|format|patch|…

    # Derived from plan.branch_template unless overridden
    branch: "{lane}/{phase_seq}-{module_id}/{wsid}"
    worktree_path: "/tmp/worktrees/{wsid}"

    path_claims:            # deny overlapping claims at schedule time
      - "modules/Domain_Router/**"

    inputs:
      cfg_ptr: "cfg/domain_router.yaml"
      bus_topics: ["files.changed"]

    constraints:
      exclusive: true
      max_runtime_sec: 600

    lifecycle:
      auto_remove_on_complete: true
      remove_on_fail: true

    merge_policy:
      target: "main"
      after_checks: ["ci/tests", "ci/lint"]

    # Pin exact code/config bytes used by this run
    pin_files:
      - role: "runner"
        path: "Domain_Router/DR-5K9.run.py"
        module_file_id: "mfid_blake3_da97…"
      - role: "rules"
        path: "Domain_Router/DR-5K9.rules.yaml"
        module_file_id: "mfid_blake3_1c21…"
```

**Notes**
- `branch` and `worktree_path` are normally derived from the plan-level templates to ensure uniqueness.
- `path_claims` allow the scheduler to reject overlapping work before creating worktrees.
- `pin_files` must be filled by reading `module_file_index.jsonl` at schedule time.

---

## 2) Workstream Manifest (runtime pinning)

Each launched workstream gets a materialized manifest in its run folder. This manifest is the single source for provenance and rollback.

```json
{
  "schema_version": "1.0",
  "wsid": "…",
  "wslid": "…",
  "phase_id": "…",
  "module_id": "DR-5K9",
  "role": "run",
  "branch": "…",
  "worktree_path": "…",
  "module_file_ids": ["mfid_blake3_da97…", "mfid_blake3_1c21…"],
  "inputs": {"cfg_ptr": "…", "bus_topics": ["files.changed"]},
  "outputs": [],
  "created_at": "…",
  "status": "planned|running|succeeded|failed"
}
```

Path: `/.runs/{plan_instance_id}/{phase_seq}/{wsid}/ws.manifest.json`

---

## 3) Module Registry & File Index (per module folder)

**`/PIPELINE_MODS/<module_key>/module.json`**
```json
{
  "module_id": "DR-5K9",
  "module_lineage_id": "{UUIDv5(\"module:Domain_Router\")}",
  "roles": ["run", "verify"],
  "contracts": {
    "input": {"type": "json", "schema": "…"},
    "output": {"type": "json", "schema": "…"}
  },
  "version": "0.1.0"
}
```

**`/PIPELINE_MODS/<module_key>/module_file_index.jsonl`** (append-only; one line per file/version)
```json
{"module_id":"DR-5K9","path":"Domain_Router/DR-5K9.run.py","role":"runner","module_file_id":"mfid_blake3_da97…","ts":"…"}
{"module_id":"DR-5K9","path":"Domain_Router/DR-5K9.rules.yaml","role":"rules","module_file_id":"mfid_blake3_1c21…","ts":"…"}
```

> The scheduler populates `pin_files` by matching on `role` → newest MFID in this index at schedule time (unless a specific MFID is requested).

---

## 4) ID Authority (append-only)

Single-writer store used to allocate WSIDs and record lineage→instance evolution. JSONL or SQLite are acceptable; JSONL line format:

```json
{"scope":"workstream","lineage_id":"…","instance_id":"…","sequence":null,
 "plan_version":"2025.10.26+rev1","created_at":"…","created_by":"orchestrator",
 "supersedes":["…"],"status":"active"}
```

Rules:
- Never mutate historical lines; only append.
- On revision of an existing lineage, mint a new `instance_id` and populate `supersedes` with the prior instance.
- Reject HRID-like aliases entirely (machine-first system does not need them).

---

## 5) Git Worktrees & Branches (derivation rules)

- **Branch** = expand `plan.branch_template` with variables: `{lane, phase_seq, phase_key, module_id, wsid}`.
- **Worktree path** = expand `plan.worktree_path_template` with `{wsid}`.
- **Uniqueness**:
  - Refuse to create a worktree if the branch is already checked out elsewhere.
  - Guarantee 1 worktree ⇄ 1 branch ⇄ 1 WSID.
- **Lifecycle**:
  - `create → run → push/queue merge → remove` (and periodic `prune` for stale/abandoned trees).

---

## 6) Ledger Lines (append-only JSONL)

All steps emit to a central ledger: `/.runs/ledger.jsonl`

```json
{"t":"ws.create","wsid":"01J…","branch":"lane/1-DR-5K9/01J…","worktree":"/tmp/worktrees/01J…","ok":true,"ms":210}
{"t":"ws.step","wsid":"01J…","module_id":"DR-5K9","module_file_id":"mfid_blake3_da97…","step":"verify","ok":true,"ms":4210}
{"t":"ws.done","wsid":"01J…","status":"succeeded","artifacts":["…"],"ms":12890}
```

---

## 7) Validation & CI Gates (machine policies)

**Pre-schedule**
- Schema validate `modification_plan.yaml` against this template.
- Resolve `path_claims` across all planned workstreams; deny overlaps if `deny_overlapping_path_claims = true`.
- Pin `module_file_ids` via `module_file_index.jsonl` and write `ws.manifest.json` for each WS.

**Runtime**
- Fail fast if a required file’s MFID changes mid-run (re-pin or abort according to policy).
- Enforce `max_runtime_sec` and `exclusive` per module.

**Merge**
- Require `merge_policy.checks` to pass for the WS before merge-queue enqueue.
- Post-merge, auto-remove worktree if `auto_remove_on_complete = true`.

---

## 8) AI Usage Guide — How to Generate a Modification Plan

1. **Discover modules**: Read `/PIPELINE_MODS/**/module.json` and build a module map `{module_key → module_id, roles, contracts}`.
2. **Choose targets**: For each desired change, pick `{phase_key, module_key, role}`.
3. **Compute IDs**:
   - `phase_lineage_id = UUIDv5("phase:<phase_key>")`; `phase_instance_id = ULID()` if new.
   - `wslid = UUIDv5("{phase_lineage_id}|{module_id}|{role}")`; `wsid = ULID()`.
4. **Derive Git**: Expand `branch_template` and `worktree_path_template` with `{lane, phase_seq, phase_key, module_id, wsid}`.
5. **Claim paths**: Add `path_claims` covering every directory/file this WS will modify.
6. **Pin files**: For each required `role`, read the module’s `module_file_index.jsonl` and set `pin_files[*].module_file_id` to the newest MFID (or a requested one).
7. **Emit plan**: Write `modification_plan.yaml` with all fields above.
8. **Materialize**: For each workstream, create its folder and write `ws.manifest.json` using the pinned MFIDs.
9. **Execute**: Create worktree, checkout branch, run the module with `in.json`/`out.json` contracts, stream ledger lines.
10. **Integrate**: On success, satisfy `merge_policy.checks`, enqueue for merge, then remove/prune worktree.

> **Determinism**: All derivations must be pure functions of `{phase_key, module_id, role, wsid}` and registry/index state at schedule time.

---

## 9) Derivation Matrix (quick reference)

| Field | Derivation |
|---|---|
| `plan.plan_instance_id` | `ULID()` at plan creation |
| `phases[].phase_lineage_id` | `UUIDv5("phase:" + phase_key)` |
| `phases[].phase_instance_id` | `ULID()` when first used in a plan revision |
| `workstreams[].wslid` | `UUIDv5(phase_lineage_id + "|" + module_id + "|" + role)` |
| `workstreams[].wsid` | `ULID()` per workstream instance |
| `branch` | `branch_template` with `{lane, phase_seq, phase_key, module_id, wsid}` |
| `worktree_path` | `worktree_path_template` with `{wsid}` |
| `pin_files[*].module_file_id` | From `module_file_index.jsonl` at schedule time |

---

## 10) Minimal Schemas (informal)

**modification_plan.yaml (YAML)**
- `version`: number, required
- `plan`: obj { ids, templates, defaults, merge_policy }
- `phases[]`: seq { phase_seq:int, phase_key:str, phase_lineage_id:str, phase_instance_id:str, timebox_weeks:int?, exit_criteria[], metrics[], risks[] }
- `workstreams[]`: seq { wslid:str, wsid:str, phase_ref{}, module_ref{}, branch:str, worktree_path:str, path_claims[], inputs{}, constraints{}, lifecycle{}, merge_policy{}, pin_files[] }

**ws.manifest.json**
- Required: `schema_version, wsid, wslid, phase_id, module_id, role, branch, worktree_path, module_file_ids[], created_at, status`

**module_file_index.jsonl**
- Lines with `{ module_id, path, role, module_file_id, ts }`

**id_authority.jsonl**
- Lines with `{ scope, lineage_id, instance_id, sequence?, plan_version, created_at, created_by, supersedes[], status }`

---

### Done
This template and guide enable a headless agent to create safe, auditable modification plans that bind *exact code bytes* to *exact workstreams*, with deterministic Git worktrees and merge policies baked in.

