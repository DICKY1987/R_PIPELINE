# Merge and rerere guidance

This repository requires deterministic merges. Before contributing, run `scripts/setup-merge-drivers.ps1` to enable rerere caching and register JSON/YAML structured merge drivers.

## rerere workflow

1. Ensure rerere is enabled by running the setup script once per machine.
2. Git will automatically record conflict resolutions. The merge-train workflow restores the cache to avoid rework.
3. If a rerere resolution is incorrect, clean the cache with `git rerere forget <path>` and re-run the merge.

See `.merge-policy.yaml` for strategy definitions and `docs/ci/merge-train.md` for the automation workflow.
