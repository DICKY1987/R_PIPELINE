Blueprint: Hybrid Git Safety & Synchronization System
Architecture Specification for Agentic Implementation
Version: 1.0
Purpose: Unified specification combining bidirectional sync with AI tool safety
Target Implementer: Agentic AI Code Generator
Output: Complete, production-ready Git automation system

I. SYSTEM OVERVIEW
A. Core Objectives

Prevent work loss from any source (tool crashes, terminal closures, system failures)
Enable parallel tool execution without conflicts or blocking
Maintain bidirectional synchronization with remote repository
Avoid infinite CI/CD loops through multiple prevention layers
Provide comprehensive recovery mechanisms for all failure modes
Minimize manual intervention through full automation

B. Architectural Principles

Defense in depth: Multiple overlapping safety mechanisms
Fail-safe defaults: Every operation preserves data
Explicit coordination: Clear boundaries between components
Observable operations: All actions leave audit trails
Idempotent by design: Safe to retry any operation
Platform-aware: Adapt to Windows vs Unix differences


II. COMPONENT ARCHITECTURE
A. System Layers (Bottom to Top)
Layer 5: User Interface (shell aliases, wrappers)
         ↓
Layer 4: Session Management (tool invocation wrappers)
         ↓
Layer 3: Workspace Isolation (Git worktrees)
         ↓
Layer 2: Synchronization Engine (bidirectional sync)
         ↓
Layer 1: Git Safety Foundation (hooks, locks, configuration)
B. Component Interaction Model
Synchronization Domain:

Polling Loop → Lock Manager → Git Operations → Remote Push/Pull
File Watcher → Debouncer → Lock Manager → Git Operations

Tool Session Domain:

Tool Wrapper → Session Branch Creator → Lock Manager → Pre/Post Hooks → Workspace Selector

Safety Domain:

Exit Traps → Emergency Checkpoint → Lock Manager → Git Operations
Post-Commit Hook → Background Push → Remote Backup

Recovery Domain:

Reflog Monitor → Dangling Commit Detector → User Notification
Stash Manager → Conflict Detector → Resolution Helper


III. DECISION MATRIX
A. Use Case Classification
Type 1: AI Tool Coordination

Multiple AI coding tools (Aider, Continue, Claude Code, Copilot)
Concurrent sessions possible
Session-level work isolation required
→ Deploy: Worktree architecture, session wrappers, tool-specific branches

Type 2: Simple Bidirectional Sync

Single user editing files
No specialized tools
Simple folder synchronization
→ Deploy: Polling loop only, direct-to-main commits, skip worktrees

Type 3: Hybrid (Data + Tools)

Mix of manual edits and AI tool usage
Occasional concurrent tool use
→ Deploy: Full hybrid system with dynamic workspace selection

Type 4: Watch-Only (Ingestion)

External process drops files
No editing, only collection
→ Deploy: File watcher with minimal safety (no exit hooks needed)

B. Platform-Specific Adaptations
Windows Requirements:

PowerShell scripts for all automation
Task Scheduler for background services
Windows Credential Manager for auth
Git for Windows installed

Unix Requirements:

Bash/Zsh scripts for all automation
Cron or systemd for background services
SSH agent or credential helper for auth
Standard Git installation


IV. FILE MANIFEST
A. Git Configuration Files
File: .git/config (local repository config)
Purpose: Establish safe defaults for all Git operations
Required Sections:

Branch auto-rebase settings
Pull with rebase preference
Push defaults (current branch, auto-setup remote)
Merge conflict style (zdiff3 for better markers)
Rebase auto-stash and auto-squash

File: .gitignore (root level)
Purpose: Exclude noise from commits
Required Patterns:

Temporary files: *.tmp, *.part, *.crdownload
Editor artifacts: ~$*, *.swp, *~
OS metadata: .DS_Store, Thumbs.db, desktop.ini
Sync system files: .sync/, SYNC.LOCK
Tool-specific temporaries based on installed tools

B. Git Hooks
File: .git/hooks/pre-close (custom, manually triggered)
Platform: Unix only (bash)
Purpose: Checkpoint work before shell exits
Trigger: Shell exit trap (configured in profile)
Behavior:

Check for uncommitted changes via porcelain status
If changes exist: stage all, commit with WIP marker and timestamp
Push to backup branch: wip/{tool_name}/{timestamp}
Non-blocking: failures don't prevent shell exit
Log success/failure to audit file

File: .git/hooks/post-commit (standard Git hook)
Platform: All
Purpose: Auto-backup every commit to remote
Trigger: Automatically after any commit
Behavior:

Push current HEAD to auto-backup/{current_branch}
Use force-with-lease (safe force push)
Run in background (don't block commit)
Silent operation (no output unless error)

File: .git/hooks/post-checkout (standard Git hook)
Platform: All
Purpose: Notify user of workspace changes
Trigger: After branch checkout
Behavior:

Display which workspace/worktree is active
Show pending work in current branch
Alert if uncommitted changes in other worktrees

C. Shell Profile Extensions
File: .det-tools/profiles/ZeroTouchGit.sh
Platform: Unix (Bash/Zsh)
Purpose: Shell-level automation and aliases
Required Content:

Export AI_TOOL_NAME environment variable
Register EXIT trap calling pre-close hook
Define safety wrapper functions
Create convenience aliases for checkpointing
Configure PATH to include tool wrappers

File: .det-tools/profiles/ZeroTouchGit.ps1
Platform: Windows (PowerShell)
Purpose: Shell-level automation and aliases
Required Content:

Set $env:AI_TOOL_NAME default
Register PowerShell.Exiting event handler
Define safety wrapper functions (cmdlets)
Create aliases for checkpointing
Configure PATH to include tool wrappers

D. Tool Session Wrappers
File: .det-tools/bin/safe-ai-session (Unix)
File: .det-tools/bin/safe-ai-session.ps1 (Windows)
Purpose: Wrap any AI tool invocation with safety
Parameters:

Tool executable name/path (required)
Pass-through arguments for the tool (variadic)
Behavior Sequence:


Set AI_TOOL_NAME from tool executable
Acquire lock via lock manager
Pre-session checkpoint: stage and commit current state
Create or switch to session branch: {tool}/{timestamp}
Detect appropriate workspace (main or tool-specific worktree)
Invoke tool with all pass-through arguments
Post-session checkpoint: stage and commit all changes
Push session branch to remote with force-with-lease
Release lock
Display session branch name and merge instructions
Return tool's exit code

E. Workspace Management
File: .det-tools/setup-worktrees.sh (Unix)
File: .det-tools/setup-worktrees.ps1 (Windows)
Purpose: Initialize worktree structure for parallel tools
Parameters:

List of tool names to create worktrees for
Optional: parent directory for worktrees (default: ..)
Behavior:
For each tool name:

Create branch tool/{name}/main if not exists
Create worktree at ../{name}-workspace on that branch
Link worktree to same .git directory as main repo
Create marker file in worktree identifying the tool


Display worktree map showing paths and branches
Create workspace routing configuration file

File: .det-tools/workspace-router.conf
Purpose: Map tool names to worktree paths
Format: Key-value pairs or JSON/YAML
Content:

Tool name → worktree absolute path
Tool name → dedicated branch name
Default workspace (main repo) for unknown tools

F. Synchronization Engine
File: .det-tools/sync/bidirectional-sync.sh (Unix)
File: .det-tools/sync/bidirectional-sync.ps1 (Windows)
Purpose: Core sync loop handling both directions
Parameters:

Interval in seconds (default: configurable, suggest 30-300)
Commit message template
Optional: webhook mode (exit after one cycle)
Behavior Sequence:
Initialization:

Verify running inside Git repository
Load configuration (interval, branches, etc.)
Enter infinite loop (unless webhook mode)


Upload Flow (each iteration):

Acquire lock (wait if unavailable, timeout after 60 seconds)
Stage all changes: git add -A
Check if staged area has changes
If yes: commit with template message including [skip ci]
Push current HEAD to origin
Release lock
Log operation (timestamp, files changed, commit hash)


Download Flow (each iteration):

Acquire lock (shared with upload flow)
Fetch all remotes with prune
Calculate divergence: commits ahead/behind upstream
If behind:

Check working directory cleanliness
If dirty: create stash with identifiable name
Execute pull with fast-forward only
If stash created: attempt pop, handle conflicts


If diverged (non-fast-forward): alert user, require manual intervention
Release lock
Log operation


Sleep/Wait:

Sleep for configured interval
Allow signal interruption (SIGTERM/SIGINT for clean shutdown)



File: .det-tools/sync/file-watcher.sh (Unix)
File: .det-tools/sync/file-watcher.ps1 (Windows)
Purpose: Event-driven alternative to polling
Dependencies: watchdog (Python) or chokidar (Node) or native filesystem APIs
Parameters:

Watch path (directory to monitor)
Recursive flag
Debounce interval (milliseconds)
Behavior:
Register handlers for file creation and modification events
Filter events through gitignore patterns
Debounce rapid successive events (batch within interval)
Trigger upload flow (via sync engine) on valid events
No download flow (orthogonal concern)

G. Lock Manager
File: .det-tools/sync/lock-manager.sh (Unix)
File: .det-tools/sync/lock-manager.ps1 (Windows)
Purpose: Centralized concurrency control
Interface (CLI or sourced functions):

acquire_lock [timeout_seconds] → success/failure
release_lock → void
check_lock → locked/unlocked
force_release_lock → void (emergency only)
Implementation Details:
Lock file location: .git/.sync.lock
Lock file content: PID, timestamp, operation name
Stale lock detection: remove if PID doesn't exist and age > threshold
Atomic file operations platform-appropriate (flock on Unix, mutex on Windows)

H. Recovery Tools
File: .det-tools/recovery/find-lost-work.sh (Unix)
File: .det-tools/recovery/find-lost-work.ps1 (Windows)
Purpose: Locate work that's not on any current branch
Behavior:

Run git reflog --all and parse output
Run git fsck --lost-found to find dangling commits
Filter by date range (optional parameter)
Filter by author/committer (optional parameter)
Display commits with:

Hash
Timestamp
Message
Files changed
Instructions to recover (cherry-pick or checkout)



File: .det-tools/recovery/list-backups.sh (Unix)
File: .det-tools/recovery/list-backups.ps1 (Windows)
Purpose: Show all auto-backup and WIP branches
Behavior:

List all remote branches matching patterns:

wip/*
auto-backup/*
*/YYYYMMDD_HHMMSS (session branches)


Group by tool name
Sort by timestamp descending
Show last commit message and age
Provide cleanup suggestions (branches older than N days)

File: .det-tools/recovery/stash-inspector.sh (Unix)
File: .det-tools/recovery/stash-inspector.ps1 (Windows)
Purpose: Examine and recover from stashes
Behavior:

List all stashes with details
Show diff for each stash
Attempt dry-run pop to detect conflicts
Provide interactive recovery options

I. CI/CD Integration
File: .github/workflows/ci-validation.yml
Purpose: Run tests/lints on all pushes
Trigger: Push to any branch EXCEPT:

Branches with [skip ci] in latest commit
Pushes from github-actions[bot]
Jobs:
Checkout code
Run validation suite (linting, tests, security scans)
Report status

File: .github/workflows/tool-branch-pr.yml
Purpose: Auto-PR tool branches to main
Trigger: Push to branches matching tool/*/main
Guard: Only if CI validation passed
Behavior:

Create or update PR from tool branch to main
Title: "Merge {tool} changes"
Labels: auto-merge, tool:{name}
Auto-merge if all checks pass (optional, configurable)

File: .github/workflows/cleanup-old-branches.yml
Purpose: Prune stale backup branches
Trigger: Scheduled (weekly recommended)
Behavior:

Find branches matching wip/* and auto-backup/* older than 30 days
Delete from remote
Comment on associated PRs (if any)

J. Configuration Files
File: .det-tools/config.yml
Purpose: Central configuration for all automation
Schema:
yamlsync:
  interval_seconds: [integer]
  mode: ["polling" | "events" | "hybrid"]
  upstream_branch: [string]
  commit_message_template: [string]
  
tools:
  enabled: [list of tool names]
  workspace_mode: ["shared" | "worktrees"]
  session_branch_pattern: [string template]
  
safety:
  auto_push_on_commit: [boolean]
  exit_checkpoint_enabled: [boolean]
  lock_timeout_seconds: [integer]
  stash_on_pull_conflict: [boolean]
  
recovery:
  backup_branch_retention_days: [integer]
  reflog_retention_days: [integer]
  
github:
  ci_skip_marker: [string]
  auto_pr_enabled: [boolean]
  auto_merge_enabled: [boolean]
File: .det-tools/platform.conf
Purpose: Platform-specific paths and commands
Content:

Git executable path
Shell executable path (PowerShell vs bash)
Credential helper type
Task scheduler command syntax

K. Monitoring & Audit
File: .det-tools/audit/operations.jsonl
Purpose: Structured log of all automation operations
Format: JSON Lines (one JSON object per line)
Schema per line:
json{
  "timestamp": "ISO8601",
  "operation": "upload|download|checkpoint|merge",
  "component": "sync-engine|tool-wrapper|hook",
  "success": true|false,
  "details": {
    "files_changed": [integer],
    "commit_hash": [string],
    "branch": [string],
    "tool": [string optional]
  },
  "error": [string optional]
}
File: .det-tools/audit/session-registry.jsonl
Purpose: Track tool sessions for debugging
Schema per line:
json{
  "session_id": "UUID",
  "tool": [string],
  "start_time": "ISO8601",
  "end_time": "ISO8601",
  "branch": [string],
  "workspace": [path],
  "commits": [array of hashes],
  "outcome": "completed|crashed|interrupted"
}
```

---

## V. OPERATIONAL WORKFLOWS

### A. Installation Sequence

**Step 1: Prerequisites Validation**
- Verify Git version >= 2.34
- Verify shell (PowerShell 7+ on Windows, bash/zsh on Unix)
- Check remote repository accessibility
- Verify write permissions to `.git/hooks`

**Step 2: Repository Configuration**
- Apply Git config settings from manifest
- Ensure `.gitignore` has required patterns
- Set user.name and user.email for automation

**Step 3: Directory Structure Creation**
- Create `.det-tools/` and all subdirectories
- Create `.det-tools/bin/`
- Create `.det-tools/profiles/`
- Create `.det-tools/sync/`
- Create `.det-tools/recovery/`
- Create `.det-tools/audit/`

**Step 4: File Materialization**
- Write all hook scripts to `.git/hooks/`
- Set executable permissions on Unix hooks
- Write all tool wrapper scripts
- Write sync engine scripts
- Write recovery tool scripts
- Write configuration templates

**Step 5: Profile Integration**
- On Windows: Add dot-source line to PowerShell $PROFILE
- On Unix: Add source line to `.bashrc` or `.zshrc`
- Provide manual verification steps for user

**Step 6: Workspace Initialization**
- If tools are enabled and workspace_mode is worktrees:
  - Run setup-worktrees script with configured tool list
  - Verify worktrees created successfully
  - Generate workspace router configuration

**Step 7: Background Service Setup**
- On Windows: Create Task Scheduler task for sync engine
- On Unix: Create systemd user service or cron job
- Configure service to start on login
- Start service immediately

**Step 8: GitHub Integration**
- If GitHub workflows enabled:
  - Create `.github/workflows/` directory
  - Write workflow YAML files
  - Commit and push workflows
  - Verify Actions enabled on repository

**Step 9: Validation Tests**
- Run test suite (see Testing section)
- Display setup summary report
- Provide next steps for user

### B. Tool Session Workflow

**Invocation:**
User executes: `safe-ai-session <tool> [args]` or alias like `tool-safe claude --help`

**Sequence:**
1. **Pre-Session State Capture**
   - Current branch recorded
   - Working directory status recorded
   - Timestamp session start

2. **Session Branch Creation**
   - Generate branch name: `{tool}/{YYYYMMDD_HHMMSS}`
   - Create branch from current HEAD
   - Checkout session branch

3. **Workspace Selection**
   - Query workspace router for tool
   - If dedicated worktree exists: switch to that worktree
   - If not: remain in main workspace

4. **Pre-Session Checkpoint**
   - Stage all current changes
   - Commit with message: "checkpoint: before {tool}"
   - Push to remote

5. **Tool Execution**
   - Set environment variable AI_TOOL_NAME
   - Execute tool with pass-through arguments
   - Capture tool exit code

6. **Post-Session Checkpoint**
   - Stage all changes made by tool
   - Commit with message: "checkpoint: after {tool}"
   - Push session branch to remote with force-with-lease

7. **Session Cleanup**
   - Display session summary:
     - Branch name
     - Number of commits made
     - Files changed
     - Merge instructions
   - Log session to registry
   - Return tool exit code

**Error Handling:**
- Tool crash: Still capture post-session state
- Push failure: Retry with backoff, alert user
- Lock timeout: Alert user, display lock holder info

### C. Synchronization Workflow

**Polling Mode (Continuous):**

**Cycle Structure:**
```
[ACQUIRE LOCK]
  ↓
[UPLOAD PHASE]
  - Stage changes
  - Detect if changes exist
  - If yes: commit, push
  ↓
[DOWNLOAD PHASE]
  - Fetch with prune
  - Calculate divergence
  - If behind: pull (with stash if dirty)
  ↓
[RELEASE LOCK]
  ↓
[SLEEP INTERVAL]
  ↓
[REPEAT]
```

**Event Mode (File Watcher):**
```
[FILE CHANGE EVENT]
  ↓
[DEBOUNCE WAIT]
  ↓
[FILTER THROUGH GITIGNORE]
  ↓
[ACQUIRE LOCK]
  ↓
[UPLOAD PHASE ONLY]
  ↓
[RELEASE LOCK]
Download Flow Detail (Critical Path):

Pre-Flight Check

Verify network connectivity
Verify remote accessible
Fetch all refs with prune


Divergence Analysis

Execute: git rev-list --left-right --count HEAD...@{upstream}
Parse output: {ahead} {behind}
If ahead > 0 AND behind > 0: Non-fast-forward scenario (alert)
If behind = 0: Already up-to-date (skip)
If behind > 0: Proceed to pull


Working Directory Assessment

Execute: git diff --quiet
If exit code 0: Clean working directory
If exit code 1: Dirty working directory (uncommitted changes)


Pull Strategy Selection

If Clean:

Execute: git pull --ff-only
If fails: Non-linear history (alert, require manual merge)


If Dirty:

Create stash: git stash push -m "sync-stash {timestamp}"
Record stash ref
Execute: git pull --ff-only
Attempt: git stash pop
If pop succeeds: Done
If pop fails (conflicts):

Leave stash in place
Alert user to conflicts
Provide conflict resolution guide
User must manually resolve and drop stash






Post-Pull Verification

Verify HEAD matches upstream
Log successful sync
Update last-sync timestamp



D. Recovery Workflows
Scenario 1: Lost Work (No Branch Reference)
Detection:

User reports work missing
No current branch contains the work
May have occurred from crash or accidental reset

Recovery Process:

Run find-lost-work tool
Filter by approximate timeframe
Display dangling commits and reflog entries
User identifies correct commit by message/timestamp
Cherry-pick commit to current branch OR
Create recovery branch from that commit
Merge recovery branch to desired location

Scenario 2: Stash Conflicts
Detection:

Download flow attempted stash pop
Merge conflicts occurred
Stash remains in stack

Recovery Process:

Run stash-inspector tool
Show conflicting stash details
Show diff of stash vs current HEAD
Options:

Attempt manual merge (tool assists)
Apply stash to new branch (isolate conflicts)
Drop stash (if changes no longer needed)


User resolves conflicts in editor
Complete merge, drop stash

Scenario 3: Branch Proliferation
Detection:

Many old backup/WIP branches exist
Repository size growing
List-backups shows branches older than retention period

Recovery Process:

Run list-backups with date filter
Group branches by age tier (30d, 60d, 90d+)
For each tier:

Verify no unmerged changes
Confirm branch pushed to remote
Delete local branch
Optional: delete remote branch


Run git garbage collection


VI. TESTING SPECIFICATION
A. Unit Tests (Per Component)
Lock Manager:

Acquire lock when available: SUCCESS
Block when lock held: WAIT then SUCCESS
Timeout after configured period: FAILURE
Stale lock detection: CLEANUP then SUCCESS
Force release: IMMEDIATE RELEASE

Upload Flow:

No changes staged: SKIP commit
Changes staged: COMMIT and PUSH
Push failure: RETRY then ALERT
Lock unavailable: WAIT then PROCEED

Download Flow:

Already up-to-date: SKIP pull
Behind, clean directory: PULL success
Behind, dirty directory: STASH, PULL, POP success
Stash pop conflict: LEAVE STASH, ALERT
Non-fast-forward: ALERT, require manual

Tool Wrapper:

Pre-checkpoint creates commit: VERIFY
Session branch created: VERIFY NAME PATTERN
Tool executed with args: VERIFY PASS-THROUGH
Post-checkpoint creates commit: VERIFY
Exit code preserved: VERIFY MATCH

B. Integration Tests
Test 1: Exit Hook Activation

Open shell in repository
Make uncommitted changes
Close shell (simulate exit)
Reopen shell
Verify: WIP commit exists with timestamp
Verify: Backup branch pushed to remote

Test 2: Concurrent Tool Sessions

Start tool session A (e.g., claude)
Without finishing A, start tool session B (e.g., aider)
Verify: Both get different session branches
Verify: No lock conflicts (if worktrees) OR serialized (if shared)
Complete both sessions
Verify: Both pushed to remote with distinct branches

Test 3: Bidirectional Sync

Start sync engine in background
Make local change, verify auto-commit and push within interval
Make remote change via GitHub web UI
Verify: Local pulls within interval
Stop sync engine
Verify: Clean shutdown, lock released

Test 4: Download with Conflicts

Make local uncommitted changes
Make conflicting remote change
Trigger download flow
Verify: Stash created
Verify: Remote change pulled
Verify: Stash pop attempted and failed
Verify: User alerted to conflicts
Verify: Stash remains in stack

Test 5: Recovery from Crash

Start tool session
Simulate crash (kill -9 or task kill)
Verify: Lock eventually released (stale detection)
Verify: Work recoverable via reflog
Run find-lost-work tool
Verify: Session branch and commits visible

C. Acceptance Criteria
System is considered operational when ALL of the following are true:

Exit hook captures work on shell close (100% success rate)
Tool sessions create isolated branches (verified for all configured tools)
Sync engine runs continuously without intervention (24+ hours)
Upload flow commits and pushes local changes within configured interval
Download flow pulls remote changes without data loss
Conflicts are detected and preserved (never silently lost)
Lock manager prevents race conditions (stress tested)
GitHub Actions workflows trigger appropriately (CI runs, auto-PR works)
Recovery tools locate all dangling work (no false negatives)
All audit logs are written correctly (parseable JSON)


VII. EDGE CASES & FAILURE MODES
A. Network Failures
Scenario: Remote unreachable during push/pull
Handling:

Push/pull operations retry with exponential backoff
After N retries (configurable), enter offline mode
Offline mode: Continue local commits, queue pushes
Periodic connectivity checks
When online: Flush queued operations
Alert user if offline > threshold (e.g., 1 hour)

B. Merge Conflicts (Non-Fast-Forward)
Scenario: Local and remote diverged, can't fast-forward
Handling:

Detect via git pull --ff-only failure
DO NOT attempt automatic merge
Alert user with detailed message:

Show divergence details (commits ahead/behind)
Provide manual merge instructions
Suggest merge vs rebase decision tree


Pause synchronization until resolved
Log conflict to audit trail

C. Lock Starvation
Scenario: Lock held indefinitely, blocking all operations
Handling:

Lock timeout enforced (default: 60 seconds)
After timeout: Check lock file for PID
If PID not running: Assume crash, force release
If PID running: Alert user, show process info
Emergency force-release command available (dangerous, requires confirmation)

D. Disk Full
Scenario: No space for commits, stashes, or fetches
Handling:

All Git operations check exit codes
Detect disk full errors
Alert user immediately
Suspend operations until space available
Suggest: Cleanup old branches, run git gc

E. Worktree Corruption
Scenario: Worktree path deleted or .git link broken
Handling:

Detect on workspace selection
Alert user to corruption
Provide repair command: git worktree repair
Offer to recreate worktree from scratch
Never silently fail

F. Credential Expiry
Scenario: PAT or SSH key no longer valid
Handling:

Detect auth failures on push/pull
Distinguish from network failures
Alert user with credential refresh instructions
Provide platform-specific guidance (Credential Manager on Windows, keychain on macOS)
Pause operations until re-authenticated


VIII. OBSERVABILITY & MONITORING
A. Health Checks
Sync Engine Health:

Last successful upload timestamp
Last successful download timestamp
Number of consecutive failures
Lock acquisition latency
Queue depth (if offline mode active)

Tool Session Health:

Active sessions count
Sessions completed successfully (last 24h)
Sessions crashed (last 24h)
Average session duration by tool

Repository Health:

Uncommitted changes count
Ahead/behind commit counts
Stash count
Backup branch count
Repository size

B. Metrics Collection
File: .det-tools/metrics/current-state.json
Update Frequency: Every sync cycle
Content: Latest values for all health check metrics
File: .det-tools/metrics/timeseries.jsonl
Update Frequency: Every sync cycle
Content: Timestamped metric snapshots for trending
C. Alerting
Alert Channels:

Console output (for foreground operations)
System notifications (OS-specific: notify-send, toast)
Audit log (always)
Optional: Webhook to external monitoring (Slack, email, etc.)

Alert Conditions:

Lock held > timeout threshold
Consecutive sync failures > 3
Merge conflict detected
Disk space < threshold
Authentication failure
Stale backup branches > retention period

D. Debugging Tools
File: .det-tools/debug/trace-operation.sh (Unix) / .ps1 (Windows)
Purpose: Verbose logging for troubleshooting
Behavior:

Accept operation type (upload, download, tool-session, etc.)
Enable debug logging (set -x on Unix, Set-PSDebug on Windows)
Execute operation
Display full command trace
Output to both console and debug log file

File: .det-tools/debug/validate-state.sh (Unix) / .ps1 (Windows)
Purpose: Sanity check entire system state
Checks:

All required files exist
All scripts are executable (Unix)
Git config has required settings
Lock file not stale
No orphaned processes
Worktrees linked correctly
Remote accessible
Hooks installed and executable
Profile integration active


IX. SECURITY CONSIDERATIONS
A. Credential Management
Requirements:

NEVER store plaintext credentials in files
Use platform credential managers:

Windows: Credential Manager or Windows Hello
macOS: Keychain
Linux: libsecret, gnome-keyring, or pass


Git credential helpers configured properly
SSH keys preferred over PAT when possible

File: .det-tools/security/credential-check.sh (Unix) / .ps1 (Windows)
Purpose: Verify credential storage security
Checks:

Credential helper configured
No credentials in .git/config
No credentials in scripts
Appropriate file permissions on SSH keys

B. Hook Execution Safety
Risks:

Hooks execute arbitrary code
Malicious commits could include hooks

Mitigations:

Hooks are NOT committed to repository (in .git/hooks, not tracked)
User installs hooks explicitly during setup
Hooks are reviewed before installation
Hooks use absolute paths, no PATH traversal
Hooks validate inputs before executing

C. Lock File Security
Risks:

Attacker creates lock to DoS system
Attacker modifies lock file

Mitigations:

Lock file in .git/ (not world-writable)
Lock file includes PID for validation
Stale lock detection prevents permanent locks
Lock timeout prevents indefinite blocking

D. Audit Log Integrity
Risks:

Tampering with audit logs
Logs grow unbounded

Mitigations:

Audit logs in JSONL format (append-only)
Log rotation configured (size or age based)
Archived logs compressed and timestamped
Optional: Sign audit logs with GPG


X. MAINTENANCE & OPERATIONS
A. Routine Maintenance Tasks
Daily (Automated):

Verify sync engine running
Check for stale locks
Rotate audit logs if size > threshold

Weekly (Automated):

Cleanup backup branches > retention period
Git garbage collection if repo size > threshold
Verify GitHub Actions workflows still active

Monthly (Manual):

Review audit logs for anomalies
Update dependencies (if using Python watchdog or Node chokidar)
Review and merge accumulated tool branches
Archive old session branches

B. Upgrade Process
Scenario: New version of system available
Process:

Backup current configuration
Stop sync engine and background services
Create system backup branch: system/backup/{timestamp}
Update scripts in .det-tools/
Update hooks in .git/hooks/
Migrate configuration if schema changed
Run validation tests
Restart services
Monitor for 24 hours
If stable: Remove backup branch

C. Decommissioning
Scenario: System no longer needed
Process:

Stop all background services
Remove hooks from .git/hooks/
Remove profile integrations (shell configs)
Optional: Cleanup all backup/WIP branches
Optional: Cleanup all worktrees
Remove .det-tools/ directory
Reset Git config to defaults
Archive audit logs if needed


XI. IMPLEMENTATION PRIORITY
Phase 1: Foundation (Week 1)
Goal: Prevent data loss
Components:

Git configuration
Lock manager
Exit hooks
Basic tool wrapper
Audit logging

Success Criteria: Exit hook captures work on shell close
Phase 2: Synchronization (Week 2)
Goal: Bidirectional sync works
Components:

Upload flow (polling mode only)
Download flow (no conflict handling yet)
Background service setup
Basic CI/CD integration

Success Criteria: Local/remote stay in sync automatically
Phase 3: Tool Integration (Week 3)
Goal: AI tools protected
Components:

Session branch logic
Tool-specific wrappers
Post-commit hook
Recovery tools (basic)

Success Criteria: Tool sessions isolated and recoverable
Phase 4: Advanced Features (Week 4)
Goal: Full hybrid system
Components:

Worktree architecture
Conflict handling in download flow
File watcher (event mode)
Complete recovery suite
GitHub auto-PR workflows

Success Criteria: Multiple tools run concurrently without conflicts
Phase 5: Production Hardening (Week 5)
Goal: Reliable long-term operation
Components:

Comprehensive error handling
Monitoring and alerting
Debug tools
Performance optimization
Documentation

Success Criteria: System runs 30+ days without intervention

XII. VALIDATION CHECKLIST
Before declaring system complete, verify ALL items:
Configuration

 Git config has all required settings
 .gitignore excludes all noise patterns
 Credential helper configured properly
 Upstream branch tracking set

Files & Structure

 All hook scripts exist and executable
 All wrapper scripts exist and executable
 Lock manager implemented and tested
 Sync engine scripts complete
 Recovery tools implemented
 Audit directory structure created
 Configuration file valid

Integration

 Shell profile extensions installed
 Hooks trigger correctly
 Background service runs on startup
 GitHub workflows present (if enabled)
 Worktrees created (if enabled)

Functionality

 Exit hook captures uncommitted work
 Tool wrapper creates session branches
 Upload flow commits and pushes
 Download flow pulls safely
 Lock prevents concurrent operations
 Conflicts detected and preserved
 Recovery tools find lost work
 CI loop prevention works

Testing

 All unit tests pass
 All integration tests pass
 Acceptance criteria met
 Edge cases handled gracefully
 Error messages are clear

Operations

 Metrics collected
 Audit logs written
 Health checks reportable
 Debug tools functional
 Maintenance tasks documented


XIII. AGENT IMPLEMENTATION NOTES
When materializing this blueprint:

Start with platform detection - determine Windows vs Unix early
Generate scripts in pairs - every .sh needs a .ps1 equivalent
Use absolute paths - don't rely on relative paths or PATH environment
Make operations idempotent - running setup twice should be safe
Validate before executing - check prerequisites before file creation
Provide rollback - if installation fails, clean up partial state
Echo progress - display what's being created/configured
Test incrementally - after each component, run its unit tests
Generate user documentation - create README with setup/usage instructions
Leave audit trail - log what was created/configured for debugging

Critical success factors:

Hook permissions (chmod +x on Unix)
Profile integration (user must source or restart shell)
Lock file location (must be in .git/ for atomicity)
Error handling (every operation must have failure path)
User communication (clear messages about what's happening)


END OF BLUEPRINT
This specification is complete and ready for agentic implementation. All components, interactions, workflows, and requirements are defined. An AI agent with file creation and script generation capabilities can materialize this entire system from this blueprint alone.