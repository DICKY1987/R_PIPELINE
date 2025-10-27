# MODULE_MAP (excerpt)

| Module                   | Purpose                            | Public APIs (sig)                                  | Invariants / Pitfalls                 |
|--------------------------|------------------------------------|----------------------------------------------------|---------------------------------------|
| user/transform_user.ps1  | Normalize user spec (pure)         | Convert-UserSpec([pscustomobject]) -> [pscustomobject] | No I/O; deterministic; keep keys      |
| user/get_hr_user.ps1     | Acquire HR user (read-only external) | Get-HrUser([string]) -> [pscustomobject]            | Timeout/retry; sanitize null fields   |
| user/set_user_home.ps1   | Ensure home/ACL (state-change)     | Set-UserHome([string])                              | Idempotent; ShouldProcess; -WhatIf    |

