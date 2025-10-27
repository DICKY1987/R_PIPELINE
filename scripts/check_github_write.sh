#!/usr/bin/env bash
# Quick permission probe for creating a reference in the repo using a token.
# Usage:
#   export GITHUB_TOKEN=ghp_xxx
#   ./scripts/check_github_write.sh owner repo
# Returns 0 on success (token can create a ref), non-zero on failure.

set -euo pipefail

if [ $# -ne 2 ]; then
  echo "Usage: $0 <owner> <repo>"
  exit 2
fi

OWNER="$1"
REPO="$2"
TOKEN="${GITHUB_TOKEN:-${GH_TOKEN:-}}"
if [ -z "$TOKEN" ]; then
  echo "Error: set GITHUB_TOKEN or GH_TOKEN environment variable with a token that has repo:contents write permissions."
  exit 2
fi

# Get main branch commit sha
MAIN_SHA=$(curl -sS -H "Authorization: token $TOKEN" -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/${OWNER}/${REPO}/git/ref/heads/main" | jq -r .object.sha 2>/dev/null || true)

if [ -z "$MAIN_SHA" ] || [ "$MAIN_SHA" = "null" ]; then
  echo "Could not read main branch ref. The repo may not have a 'main' branch or token cannot read refs."
  exit 1
fi

RANDOM_REF="refs/heads/tmp-perm-test-$(date +%s)-$RANDOM"
# Try to create a temporary ref (requires write)
create_resp=$(curl -sS -o /dev/stderr -w "%{http_code}" -X POST \
  -H "Authorization: token $TOKEN" -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/${OWNER}/${REPO}/git/refs" \
  -d "{\"ref\":\"${RANDOM_REF}\",\"sha\":\"${MAIN_SHA}\"}" 2>/dev/null) || true

if [ "$create_resp" = "201" ]; then
  echo "Success: token can create refs (write permission present). Cleaning up..."
  # delete the test ref
  curl -sS -X DELETE -H "Authorization: token $TOKEN" -H "Accept: application/vnd.github+json" \
    "https://api.github.com/repos/${OWNER}/${REPO}/git/refs/heads/${RANDOM_REF#refs/heads/}" > /dev/null
  exit 0
else
  echo "Failure: token could not create refs. HTTP status: $create_resp"
  echo "Ensure the token has repo write permissions or grant the GitHub App write access for this repository."
  exit 1
fi