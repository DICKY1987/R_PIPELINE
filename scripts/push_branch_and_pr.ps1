#!/usr/bin/env pwsh
# PowerShell variant to create branch, commit, push, and open PR with gh.
param(
  [string]$Branch = 'r-pipeline/phase1-watcher',
  [string]$CommitMsg = 'Harden build.ps1 (ruff/pyright), add consumer, expand integration CI'
)

if ((git status --porcelain) -ne '') {
  Write-Error 'Working tree not clean. Please stash or commit changes first.'
  exit 1
}

git fetch origin main
git checkout -b $Branch origin/main

# Add files to commit (adjust as needed)
git add watcher/build.ps1, watcher/consumer.py, .github/workflows/watcher-ci.yml
git commit -m $CommitMsg
git push --set-upstream origin $Branch

if (Get-Command gh -ErrorAction SilentlyContinue) {
  gh pr create --base main --head $Branch --title 'Phase 1: Streamlined watcher + build + tests' `
    --body 'Implemented watcher/watch.ps1, build.ps1, py_check.py, pytest tests, Pester tests, configs, and CI; hardened build.ps1 to call ruff/pyright/Invoke-ScriptAnalyzer when available; added integration CI test exercising watch->build->.runs outputs.'
} else {
  Write-Host "gh CLI not available. Branch pushed. Create PR in GitHub UI."
}