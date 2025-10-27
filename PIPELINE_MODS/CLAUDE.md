# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is the **AI Upkeep Suite v2** - a comprehensive code quality enforcement system built around the Model Context Protocol (MCP). It creates a controlled environment where AI agents can generate, modify, and maintain code while being constrained by deterministic guardrails, automated validation pipelines, and policy-as-code enforcement.

**Core Purpose**: Force higher-quality AI code output across PowerShell, Python, and TypeScript by centralizing all code-quality tools (formatters, linters, test runners, SAST, secret scanners) behind MCP servers with guardrail chains and SafePatch validation.

## Technology Stack

- **PowerShell** (5.1 + 7.4): PSScriptAnalyzer, Pester
- **Python** (3.12): ruff, black, mypy, pytest
- **TypeScript/JavaScript**: ESLint, Prettier, tsc
- **SAST**: Semgrep
- **Policy**: OPA/Conftest
- **CI/CD**: GitHub Actions (Windows-first)

## Key Architecture Components

### 1. MCP Tool Plane
All code quality operations are invoked through MCP servers with access control groups:
- `code.format.*` → black/ruff, Prettier
- `code.lint.*` → Ruff, ESLint, PSScriptAnalyzer
- `code.typecheck.*` → mypy, tsc
- `code.test.*` → pytest, Pester
- `code.sast.*` → Semgrep
- `code.secrets.*` → secret scanner
- `code.policy.*` → Conftest/OPA

### 2. SafePatch Validation Pipeline
Every AI diff must pass this sequential pipeline before commit/PR:
```
format → lint → typecheck → unit tests (sandbox) → SAST → policy → secrets → SBOM
```

### 3. Guardrail Contracts
AI outputs must conform to structured schemas:
- **ChangePlan JSON**: Required fields (repo, rationale, changes, tests, risk, gates)
- **UnifiedDiff**: Standard unified diff format; whole-file rewrites rejected unless permitted
- **Delivery Bundles**: Must include tests, config files, and validation scripts

### 4. Access-Scoped Execution
Per-key/team access groups (reader, contributor, maintainer) control which MCP tools a caller can see/use.

### 5. Audit & Observability
Append-only JSONL ledgers with cryptographic signatures for all operations.

## Development Workflow

### Running Local Validation (PowerShell)
```powershell
# Run PSScriptAnalyzer and Pester (mirrors CI)
.\tools\Verify.ps1

# With CI mode (for automation)
.\tools\Verify.ps1 -CI

# Skip module installation
.\tools\Verify.ps1 -NoInstall
```

### Running SafePatch Validation
```powershell
# Full validation pipeline on a change
.\scripts\validation\Invoke-SafePatchValidation.ps1 -ChangePlanPath .\changeplan.json

# Individual validation steps
.\scripts\validation\Invoke-FormatCheck.ps1 -Path .\src
.\scripts\validation\Invoke-LintCheck.ps1 -Path .\src
.\scripts\validation\Invoke-TypeCheck.ps1 -Path .\src
.\scripts\validation\Invoke-UnitTests.ps1 -Path .\tests
.\scripts\validation\Invoke-SastScan.ps1 -Path .\src
.\scripts\validation\Invoke-SecretScan.ps1 -Path .\src
```

### MCP Configuration Management
```powershell
# Initialize MCP environment from config
.\\.mcp\Initialize-McpEnvironment.ps1 -Path .\.mcp\mcp_servers.json -Verbose

# Get current MCP configuration
.\\.mcp\Get-McpConfiguration.ps1

# Test MCP environment health
.\\.mcp\Test-McpEnvironment.ps1
```

### Python Testing
```bash
# Run all tests with pytest
pytest

# Run specific test file
pytest tests/unit/test_changeplan_validator.py

# Run with coverage
pytest --cov=scripts --cov-report=html
```

### Pre-commit Hooks
```bash
# Install pre-commit hooks
pre-commit install

# Run all hooks manually
pre-commit run --all-files

# Run on staged files only
pre-commit run
```

## Code Standards & Conventions

### PowerShell Requirements
**Every PowerShell script/function must have**:
- `#Requires -Version 5.1`
- `Set-StrictMode -Version Latest`
- `$ErrorActionPreference='Stop'`
- `[CmdletBinding(SupportsShouldProcess=$true)]` for functions
- Validated parameters with types
- Comment-based help
- Pester tests
- **Approved Verbs only** (Get-, Set-, New-, etc.)
- **No Write-Host** for core output (use Write-Output or structured logging)
- **No aliases**
- Try/Catch with structured error handling

### Python Requirements
- **Type hints** on all function signatures
- **argparse** for CLI interfaces (not raw input)
- **logging** for all output (no print() except final result)
- **main()** function with proper exit codes
- **pytest** tests for all modules
- Pass black, ruff, and mypy strict mode

### TypeScript Requirements
- `tsconfig.json` with `"strict": true`
- ESLint with no warnings
- Prettier formatting

### Universal Requirements
- **Minimal diffs**: Propose unified diffs, not whole-file rewrites
- **Tests first**: Generate tests alongside code
- **No external network calls** in validation/test environments
- **Idempotent operations**: Safe to re-run
- **JSONL event logging** for auditability

## Critical File Locations

### Configuration Files
- `.mcp/mcp_servers.json` - MCP server definitions
- `.mcp/access_groups.json` - Access control groups
- `tools/PSScriptAnalyzerSettings.psd1` - PowerShell linter config
- `tools/ruff.toml` - Python linter config
- `tools/mypy.ini` - Python type checker config
- `.pre-commit-config.yaml` - Pre-commit hook configuration

### Policy & Schemas
- `policy/schemas/changeplan.schema.json` - ChangePlan JSON Schema
- `policy/opa/changeplan.rego` - OPA policy for ChangePlans
- `policy/opa/forbidden_apis.rego` - Forbidden API patterns
- `.semgrep/semgrep.yml` - SAST rules (base)
- `.semgrep/semgrep-powershell.yml` - PowerShell-specific rules
- `.semgrep/semgrep-python.yml` - Python-specific rules

### Templates
- `templates/powershell/AdvancedFunction.ps1` - Self-defensive PS function template
- `templates/python/python_cli.py` - Python CLI template
- `templates/powershell/Pester.Tests.ps1` - Pester test template

### Database
- `database/schema.sql` - SQLite/Postgres schema for access groups, policies, ledger
- `schemas/ledger.schema.json` - Run ledger entry schema

## Working with AI Agents in This System

### Agent Output Requirements
When generating code, AI agents MUST:

1. **Emit ChangePlan JSON first** with:
   - repo, rationale, changes[], tests[], risk level, gates[]
   - Changes as unified diffs (not full file contents)
   - Test stubs for verification

2. **Follow language-specific scaffolds**:
   - PowerShell: Start from `templates/powershell/AdvancedFunction.ps1`
   - Python: Start from `templates/python/python_cli.py`

3. **Pass all validation gates**:
   - Format check (black/ruff/prettier)
   - Lint check (PSScriptAnalyzer/ruff/ESLint)
   - Type check (mypy/tsc)
   - Unit tests (Pester/pytest)
   - SAST (Semgrep)
   - Policy (OPA/Conftest)
   - Secrets scan

### Forbidden Patterns
AI agents MUST NOT generate code with:
- `Write-Host` for PowerShell output (use Write-Output)
- `Invoke-Expression` or eval() calls
- `subprocess.Popen(..., shell=True)` in Python
- Bare `print()` in Python (except final output)
- Unapproved PowerShell verbs
- PowerShell aliases
- Network calls in test/validation code
- Untyped parameters

### Edit Strategies (Prefer smaller changes)
1. **Config changes**: Use JSON Patch (RFC 6902)
2. **Code fixes**: Use unified diff format
3. **Mechanical refactors**: Use Comby or AST codemods
4. **Full rewrites**: Last resort only

## CI/CD Pipeline

### GitHub Actions Workflows
- `.github/workflows/quality.yml` - Main orchestrator
- `.github/workflows/powershell-verify.yml` - Windows runner for PS
- `.github/workflows/python-verify.yml` - Python validation
- `.github/workflows/sast-secrets.yml` - Security scanning
- `.github/workflows/drift-detection.yml` - Nightly guardrail checks

### Branch Protection Requirements
- All quality checks must pass
- CODEOWNERS review required
- Linear history enforced
- No force-pushes to main

## File Routing System

The project includes an automated file routing system for organizing downloads:

**Naming Convention**: `PROJECT-AREA-SUBFOLDER__name__timestamp__version__ulid__sha8.ext`

**Example**: `HUEY-PS-SCRIPTS__flatten-directory__20251015T081530Z__v1.0.0__u01JAB8...__s7a1c9e2.ps1`

**Usage**:
```powershell
# Start the file router watcher
pwsh -File .\file-routing\FileRouter_Watcher.ps1 -ConfigPath .\file-routing\file_router.config.json
```

Files are automatically routed from Downloads to project directories based on naming convention.

## Common Troubleshooting

### PSScriptAnalyzer Failures
- Check `tools/PSScriptAnalyzerSettings.psd1` for active rules
- Run `Invoke-ScriptAnalyzer -Path . -Recurse` to see specific violations
- Common issues: unapproved verbs, aliases, missing help

### Pester Test Failures
- Tests run in sandbox with no network
- Check for hardcoded paths (use relative paths)
- Verify all dependencies are mocked

### MCP Server Connection Issues
- Use `.\\.mcp\Test-McpEnvironment.ps1` to verify health
- Check server logs in `.det-logs/`
- Ensure environment variables are set correctly

### Pre-commit Hook Failures
- Run `pre-commit run --all-files` to see all violations
- Fix formatting first (black, ruff, prettier auto-fix)
- Then address linting and type issues

## Development Phases

The project follows a phased rollout strategy:

**Phase 0**: Foundation (schemas, directory structure, conventions) - COMPLETE
**Phase 1**: Parallel streams (MCP config, guardrails, quality tools, templates, sandbox, audit) - IN PROGRESS
**Phase 2**: Integration (SafePatch pipeline, MCP servers, pre-commit) - PENDING
**Phase 3**: CI/CD & Testing - PENDING
**Phase 4**: Documentation & Refinement - PENDING

See `Development Order - Parallel Streams Strategy.md` for detailed implementation plan.

## Key Design Principles

1. **Deterministic First**: Prefer scripted edits over AI where possible
2. **Minimal Diffs**: Smallest possible changes reduce risk
3. **Schema-Constrained**: AI outputs must conform to validated schemas
4. **Offline Validation**: Sandboxes run without network access
5. **Audit Everything**: Append-only logs with cryptographic signatures
6. **Fail Fast**: Block commits/PRs that don't pass all gates
7. **Windows-First**: Primary development on Windows, cross-platform CI

## Additional Resources

- Main specification: `spec_1_ai_upkeep_suite_v_2_guardrails_mcp.md`
- Development plan: `Development Order - Parallel Streams Strategy.md`
- System analysis: `AIUOKEEP.md`
- MCP integration guide: `Connect Claude Code to tools via MCP.md`
- Multi-document reference: `MULTI_DOC_fILES.md`
