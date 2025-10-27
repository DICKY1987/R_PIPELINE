#!/usr/bin/env bash
# Create branch from origin/main, add staged files, commit, push and open PR using gh.
# Usage:
#   ./scripts/push_branch_and_pr.sh r-pipeline/phase1-watcher "Commit message"
# Prereqs: gh CLI authenticated OR set GITHUB_TOKEN and have git remotes configured.

set -euo pipefail

BRANCH="${1:-r-pipeline/phase1-watcher}"
COMMIT_MSG="${2:-\"Harden build.ps1 (ruff/pyright), add consumer, expand integration CI\"}"

# Ensure clean working tree (optional)
if [ -n "$(git status --porcelain)" ]; then
  echo "Working tree not clean. Please stash or commit changes, or run with a clean tree."
  git status --porcelain
  exit 1
fi

# Fetch and base on origin/main
git fetch origin main
git checkout -b "$BRANCH" origin/main

# Add specific files (change list to match files you want to commit)
git add watcher/build.ps1 watcher/consumer.py .github/workflows/watcher-ci.yml
# Also add other watcher files if needed:
# git add watcher/py_check.py watcher/tests watcher/test_sample.ps1 watcher/test_sample.Tests.ps1 watcher/watch.config.json watcher/watch.ignore watcher/pyproject.toml watcher/PSScriptAnalyzer.psd1 watcher/.gitignore watcher/README.md .runs/watch/.gitkeep

git commit -m "$COMMIT_MSG"

# Push branch
git push --set-upstream origin "$BRANCH"

# Create PR using gh if available, else print instructions
if command -v gh >/dev/null 2>&1; then
  gh pr create --base main --head "$BRANCH" --title "Phase 1: Streamlined watcher + build + tests" \
    --body "Implemented watcher/watch.ps1, build.ps1, py_check.py, pytest tests, Pester tests, configs, and CI; hardened build.ps1 to call ruff/pyright/Invoke-ScriptAnalyzer when available; added integration CI test exercising watch->build->.runs outputs."
else
  echo "gh CLI not found. Branch pushed. Create a PR from $BRANCH to main in the GitHub UI or install gh."
fi

echo "Done."