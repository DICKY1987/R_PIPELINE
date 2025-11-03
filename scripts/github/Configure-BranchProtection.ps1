Set-StrictMode -Version Latest

[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$Repository,
    [Parameter()][string]$Branch = 'main'
)

$gh = Get-Command gh -ErrorAction SilentlyContinue
if (-not $gh) {
    throw 'GitHub CLI (gh) is required.'
}

gh api repos/$Repository/branches/$Branch/protection --method PUT --input - <<'JSON'
{
  "required_status_checks": {
    "strict": true,
    "contexts": ["merge-train", "SafePatch"]
  },
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "require_code_owner_reviews": true
  },
  "restrictions": null,
  "required_linear_history": true,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "block_creations": false,
  "required_conversation_resolution": true
}
JSON

gh repo edit $Repository --delete-branch-on-merge true | Out-Null
