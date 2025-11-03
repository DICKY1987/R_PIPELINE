# Merge-train workflow

The `merge-train.yml` workflow executes SafePatch verification and deterministic merges.

## Triggers

- `workflow_dispatch`: manual runs when curating batches.
- `schedule`: nightly validation of pending change sets.
- `push`: protected branches invoke the train after policy checks.

## Steps

1. Restore rerere cache artifact.
2. Run `scripts/PreFlight-Check.ps1` to validate environment.
3. Execute `scripts/AutoMerge-Workstream.ps1` to orchestrate merges.
4. Upload artifacts for audit under `.merge-policy.yaml` guidance.
5. Quarantine failures for manual review.

Refer to `docs/merge/README.md` for rerere setup and `docs/SAFE_PATCH_RULES.md` for required gates.
