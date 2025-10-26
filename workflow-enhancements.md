# Workflow Execution Enhancements

## Overview

The CLI Orchestrator has been enhanced with comprehensive Git snapshot tracking, activity logging, and visual feedback for workflow execution. These features provide better observability, auditability, and user experience.

## New Features

### 1. Git Snapshot Tracking

Workflows now automatically capture Git repository state before and after execution.

**Captured Information:**
- Branch name
- Commit hash (short form)
- Last commit message and time
- Recent commits count
- Unpushed commits count
- Uncommitted files list
- Repository status (clean/dirty)

**Example Snapshot:**
```json
{
  "branch": "main",
  "commit_hash": "abc1234d",
  "last_commit_message": "feat: add new feature",
  "last_commit_time": "2 hours ago",
  "recent_commits": 3,
  "unpushed_commits": 0,
  "uncommitted_files": ["src/foo.py", "src/bar.py"],
  "status": "dirty",
  "timestamp": "2025-09-30T19:24:55Z"
}
```

### 2. Enhanced Session IDs

Run IDs now use a human-readable format: `yyyyMMdd-HHmmss-6hex`

**Example:** `20250930-142455-a1b2c3`

**Benefits:**
- Sortable by timestamp
- Unique with random suffix
- Easy to identify workflow runs

### 3. Startup Banner

Workflows display a visual banner at startup showing:
- Workflow name
- Run ID
- Cost tracking status
- Verification gates status

**Example:**
```
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║   🚀 CLI ORCHESTRATOR - WORKFLOW EXECUTION                  ║
║                                                              ║
║   Workflow:      Python Edit + Triage                       ║
║   Run ID:        20250930-142455-a1b2c3                     ║
║   Cost Tracking: ✓ ENABLED                                  ║
║   Verification:  ✓ ENABLED                                  ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
```

### 4. Exit Summary

Workflows display a comprehensive summary on completion:
- Execution duration
- Steps executed
- Tokens used
- Git changes (commits created, unpushed, branch)
- Success/failure status

**Example:**
```
╔══════════════════════════════════════════════════════════════╗
║   💾 WORKFLOW EXECUTION SUMMARY                             ║
║                                                              ║
║   Duration:          0:02:15                                 ║
║   Steps Executed:    5                                       ║
║   Tokens Used:       12500                                   ║
║                                                              ║
║   Git Changes:                                               ║
║   - Commits Created: 2                                       ║
║   - Unpushed:        0                                       ║
║   - Branch:          main                                    ║
║                                                              ║
║   Status: ✓ SUCCESS                                         ║
╚══════════════════════════════════════════════════════════════╝
```

### 5. Enhanced Workflow Manifest

Workflow manifests now include comprehensive Git snapshots and statistics.

**Manifest Location:** `artifacts/{run-id}/manifest.json`

**Example Manifest:**
```json
{
  "run_id": "20250930-142455-a1b2c3",
  "workflow_name": "Python Edit + Triage",
  "created": "2025-09-30T19:24:55Z",
  "ended": "2025-09-30T19:27:10Z",
  "duration_seconds": 135.5,
  "git_snapshot_start": {
    "branch": "main",
    "commit_hash": "abc1234",
    "status": "clean",
    "uncommitted_files": []
  },
  "git_snapshot_end": {
    "branch": "main",
    "commit_hash": "def5678",
    "status": "dirty",
    "uncommitted_files": ["src/foo.py"]
  },
  "statistics": {
    "duration_seconds": 135.5,
    "steps_executed": 5,
    "tokens_used": 12500,
    "success": true,
    "commits_created": 2,
    "files_modified": 1
  },
  "artifacts": ["artifacts/diagnostics.json"]
}
```

### 6. Activity Logging

Real-time structured logging to `logs/workflow_execution.log`

**Log Format:**
```
[2025-09-30 14:30:22] [INFO] Workflow started: Python Edit + Triage {"run_id": "20250930-142455-a1b2c3", "cost_tracking": true}
[2025-09-30 14:30:23] [INFO] Git pre-workflow: main @ abc1234 {"branch": "main", "commit_hash": "abc1234", "status": "clean"}
[2025-09-30 14:30:25] [INFO] Step started: 1.001 - VS Code Diagnostic Analysis {"step_id": "1.001", "actor": "vscode_diagnostics"}
[2025-09-30 14:32:10] [INFO] Step completed: 1.001 - VS Code Diagnostic Analysis {"step_id": "1.001", "success": true}
[2025-09-30 14:32:37] [INFO] Workflow completed successfully: Python Edit + Triage {"run_id": "20250930-142455-a1b2c3", "duration_seconds": 135.5}
```

**Real-time Monitoring:**
```bash
# Unix/Mac/Linux:
tail -f logs/workflow_execution.log

# Windows PowerShell:
Get-Content logs\workflow_execution.log -Wait -Tail 20
```

### 7. Log Rotation

Automatic log rotation when files exceed size limits:
- Default max size: 10 MB
- Default max files: 3
- Rotated files: `activity.log.1`, `activity.log.2`, `activity.log.3`

## API Usage

### Git Snapshot Capture

```python
from cli_multi_rapid.adapters.git_ops import GitOpsAdapter

git_ops = GitOpsAdapter()

# Capture snapshot with 10-minute lookback
snapshot = git_ops.capture_git_snapshot(lookback_minutes=10)

# Get session statistics
from datetime import datetime
start_time = datetime.now()
# ... run workflow ...
stats = git_ops.get_session_statistics(start_time)
```

### Activity Logger

```python
from cli_multi_rapid.logging import ActivityLogger
from pathlib import Path

logger = ActivityLogger(Path("logs/activity.log"))

# Log different levels
logger.info("Workflow started", run_id="abc123")
logger.warning("Low disk space", available_gb=5.2)
logger.error("Step failed", step_id="1.001", error="Connection timeout")

# Log workflow events
logger.workflow_started("My Workflow", "run-123")
logger.workflow_completed("My Workflow", "run-123", success=True)

# Log Git snapshots
logger.git_snapshot(snapshot, event_type="pre-workflow")
```

### Session ID Generation

```python
from cli_multi_rapid.workflow_runner import WorkflowRunner

runner = WorkflowRunner()

# Generate new run ID
run_id = runner.generate_run_id()
# Example: "20250930-142455-a1b2c3"
```

## Configuration

### Monitoring Configuration

Create `.ai/config/monitoring.json`:

```json
{
  "logging": {
    "activity_log_enabled": true,
    "activity_log_path": "logs/activity.log",
    "rotation": {
      "max_size_mb": 10,
      "max_files": 3
    }
  },
  "git_tracking": {
    "enabled": true,
    "snapshot_interval": "pre_post",
    "lookback_minutes": 10
  }
}
```

## CLI Commands

```bash
# Run workflow with enhanced logging
cli-orchestrator run .ai/workflows/PY_EDIT_TRIAGE.yaml

# Monitor workflow execution in real-time
tail -f logs/workflow_execution.log

# View workflow manifest
cat artifacts/{run-id}/manifest.json | jq .

# Check Git snapshot history
jq '.git_snapshot_start, .git_snapshot_end' artifacts/{run-id}/manifest.json
```

## Benefits

1. **Auditability**: Complete record of workflow execution and Git state changes
2. **Debugging**: Real-time logs and detailed manifests for troubleshooting
3. **Metrics**: Track workflow performance, token usage, and code changes
4. **Safety**: Know exactly what changed during workflow execution
5. **Recovery**: Git snapshots enable rollback and conflict resolution

## Schema Contracts

New Pydantic contracts available:

```python
from cli_multi_rapid.contracts import (
    GitSnapshot,
    GitStatus,
    GitSessionStatistics,
    SessionMetadata,
    SessionStatus,
)
```

## Migration Notes

- Existing workflows automatically gain new features
- No breaking changes to workflow YAML syntax
- Manifests now include additional Git tracking fields
- Activity logs create automatically in `logs/` directory
- All new features are backward compatible

## Performance Impact

- Git snapshot capture: < 100ms per snapshot
- Activity logging: < 10ms per log entry (async writes)
- Banner display: < 50ms
- Total overhead: < 1% for typical workflows

## Future Enhancements

Planned features:
- Web dashboard for workflow execution history
- Slack/Discord notifications for workflow completion
- Advanced Git conflict detection and resolution
- Workflow execution replay from manifests
- Performance trend analysis
