fully machine-first. Here’s a tight, ID-centric design that binds workstreams ⇄ modules ⇄ files with zero human-readable overhead.

1) The four IDs (each solves a different problem)

module_id (MID): deterministic, short, tied to the module folder (e.g., your Two-ID like DR-5K9). Never changes unless the module is renamed at the conceptual level.

module_file_id (MFID): content-addressed ID per file (e.g., blake3(path_norm + content_hash)[:20]). Changes on edit; lets you prove exactly which file bytes a run used.

workstream_lineage_id (WSLID): deterministic, version-agnostic identity for “this kind of workstream” (e.g., UUIDv5 over phase_key|module_id|role).

workstream_instance_id (WSID): a fresh, time-sortable run ID (ULID/UUIDv7) created whenever the planner spawns a workstream.

Why both lineage + instance? The lineage groups all revisions/reruns of “the same logical stream,” while instance pins an exact run (great for provenance and rollback).

2) Where IDs live (machine files only)

/PIPELINE_MODS/registry.yaml (authoritative): { module_key → { module_id, lineage_id, attrs… } }.

/PIPELINE_MODS/<module_key>/module.json: { module_id, lineage_id, roles[], version, contracts[] }.

/PIPELINE_MODS/<module_key>/module_file_index.jsonl: one line per file → { path, role, module_id, module_file_id, ts }.

/_machine/id_authority.sqlite (or .jsonl if you prefer): single-writer store that allocates WSIDs and keeps the last issued sequences to avoid races.

/.runs/<plan_run_ulid>/<phase_seq>/<WSID>/ws.manifest.json: the live binding for that workstream:
{ wsid, wslid, phase_id, module_id, module_file_ids[], inputs, outputs, cfg_hash }.

3) Folder & filename binding (no human docs)

Module folder: stable module_key/ (e.g., Domain_Router_…_MOD/).

Files: keep your TID prefix for fast machine matching (e.g., DR-5K9.run.py, DR-5K9.rules.yaml). Your guard process derives/updates MFIDs and refreshes module_file_index.jsonl on every save.

Stable import surface: auto-generate a tiny api.py inside the module that re-exports from the TID-prefixed files; agents import modules.<module_key>.api only (so renames don’t break callers).

4) How a workstream binds to modules & files (the handshake)

Planner picks (phase_id, module_key, role) → computes WSLID (UUIDv5).

Allocator mints WSID (ULID) and writes ws.manifest.json.

The module runner loads module.json and the current module_file_index.jsonl, selecting the exact file(s) it needs by role.

It pins MFIDs into the manifest before execution: no ambiguity about which code/config/schema it used.

During execution, each artifact record in the ledger includes { wsid, module_id, module_file_id, step, outcome }.

5) Queues, locks, and routing (fully headless)

Queue names: q/<module_id>/<role> (e.g., q/DR-5K9/run). Messages carry { wsid, wslid, inputs_ptr }.

Single-writer allocation: id_authority.sqlite uses row-level locks (BEGIN IMMEDIATE) to atomically grant WSIDs and bump any per-module/per-phase counters you want.

File locks: optional locks/<module_id>/<role>.lck if you need “one runner at a time” semantics.

6) Provenance baked into artifacts (no prose)

Every generated artifact (script, workflow, patch) gets a tiny machine header (comment or sidecar JSON) with:
{ wsid, wslid, module_id, module_file_ids[], source_ledger_ids[] }.

Your Provenance/Rollback step copies those claims into a central index; a rollback only needs the WSID to reconstruct the exact inputs.

7) Collisions, renames, and edits (self-healing rules)

module_id collisions: extend the hash shard length once and update registry.yaml; guard refuses future reuse.

File edits: MFID changes; the next run pins the new MFID automatically via the index. Old runs remain provable because their manifests carry the old MFIDs.

Refactors/renames: the guard updates module_file_index.jsonl; importer resolves by role first, then MFID. If both change, the next run fails fast until the role→file mapping is reasserted (machine check).

8) Minimal runtime contracts (so everything composes)

Module run contract (stdin/stdout or files):
in.json → { wsid, inputs[], cfg } and out.json → { wsid, artifacts[], metrics }.
The runner echoes back the MFIDs it actually loaded (belt-and-suspenders).

Ledger line (append-only JSONL):
{"t":"ws.step","wsid":"01J…","module_id":"DR-5K9","module_file_id":"mfid_…","step":"verify","ok":true,"ms":4210}.

9) End-to-end example (concrete but code-free)

Planner: phase=PH02, module=Domain_Router, role=run → WSLID=v5(“PH02|DR-5K9|run”), WSID=01JF….

Module selects DR-5K9.run.py (MFID=mf_da97…) + DR-5K9.rules.yaml (MFID=mf_1c21…).

Runner writes /.runs/.../ws.manifest.json pinning both MFIDs, and the ledger logs every step with those IDs.

Exported artifact carries { wsid, wslid, module_id, [mf_da97…, mf_1c21…] } in its header/sidecar.

10) What to implement first (tiny, mechanical pieces)

registry.yaml (module keys → module_id, lineage_id).

nameguard that (a) enforces TID prefixes, (b) maintains module_file_index.jsonl, (c) emits MFIDs.

id_authority.sqlite (or JSONL + file lock) for WSID allocation.

ws.manifest.json schema and a small helper that writes it before each run.

ledger.jsonl writer (append-only).

runner shim that echoes back which MFIDs it imported.

This gives you airtight, self-describing executions: every workstream instance is linked to the exact module folder and the exact file bytes it ran—no human names, no docs, no ambiguity.