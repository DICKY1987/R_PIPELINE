# Test Gap Report

_Last updated: 2025-10-23_

## Repository Inventory

| Language | Primary Frameworks | Existing Coverage Status |
| --- | --- | --- |
| Python | `pytest`, `coverage.py` (`pytest.ini`, `.coveragerc`, `pyproject.toml`) | Unit, integration, and contract suites exist under `tests/`, but multiple legacy cases (e.g., `tests/unit/test_workflow_runner.py`) fail against the current implementation. Baseline run (`pytest tests/unit -q`) produced **12.14%** coverage (see `.reports/baseline/20251023T122023Z/coverage.xml`). |
| PowerShell | Pester v5 (`tests/pester/*.Tests.ps1`) | Several domain-specific suites exist, but there was no repository-level Pester configuration or coverage gating. |
| Node.js | None configured (`package.json` lacks a `test` script) | No automated JS/TS tests; only OpenAPI lint tooling is defined. |

## Recent Additions (This Work)

- Python unit coverage for `cli_multi_rapid.security.rbac.RoleBasedAccessControl` and `cli_multi_rapid.security.auth.APIKeyManager` (`tests/unit/test_security_rbac.py`, `tests/unit/test_security_auth.py`).
- PowerShell Pester coverage for `scripts/TradingOps/TradingOps.psm1` (`tests/pester/TradingOps.Tests.ps1`).
- Unified runner (`scripts/run_all_tests.ps1`), Makefile targets, CI workflow, and documentation to enforce 85% coverage on the exercised modules.

## Python Coverage Gaps

Large portions of `src/cli_multi_rapid` remain untested because historical suites rely on private APIs or heavyweight external tooling. The table below highlights the highest-priority gaps based on the coverage snapshot.

| Module | Current Issues | Proposed Test Scenarios |
| --- | --- | --- |
| `src/cli_multi_rapid/workflow_runner.py` | Legacy unit tests expect removed private helpers (`_load_workflow`, `_execute_step`, etc.), causing consistent failures that block CI. | Add acceptance-style tests around the public `WorkflowRunner.run_workflow` entry point using fixture workflows. Introduce dependency injection seams (e.g., mock router/validator) to assert validation failures, dry-run behaviour, and error propagation. |
| `src/cli_multi_rapid/router.py` | 15% coverage; heavily coupled to adapter factory with subprocess calls (`aider`, `git`, `pytest`). | Split into pure decision helpers and side-effectful adapter loading. Unit-test routing heuristics with fake adapter registry, covering deterministic vs. AI routing, token limits, and error escalation paths. |
| `src/cli_multi_rapid/security.audit` | 12% coverage; tamper-evident hash chain and redaction routines unverified. | Test `_compute_last_hash` on empty/legacy/new log formats, `_redact_details` for sensitive keys/email masking, and `log_event` hash chaining (using temp directories + asyncio loop). Include negative cases where file I/O fails. |
| `src/cli_multi_rapid/security.framework` | 29% coverage; complex security policy bootstrap, user creation, and rate limiting untested. | Exercise `_setup_default_permissions`, `create_user` validation errors, API key + JWT integration (mock `JWTManager`/`APIKeyManager`), and rate-limit tracking with time manipulation. |
| `src/cli_multi_rapid/security.auth.JWTManager` | Uncovered due to optional PyJWT dependency. | Use `pytest.importorskip('jwt')` guarded tests to validate token issuance, expiry handling, and decode fallback when `verify_signature=False`. |
| `src/cli_multi_rapid/setup/*.py` | 0% coverage; heavy file-system and subprocess orchestration. | Introduce fixtures with temporary directories and stub command runners to verify environment validation, tool discovery fallbacks, and reporting of missing prerequisites. |
| `src/cli_multi_rapid/logging/*.py` | 0% coverage; custom loggers, rotation, and activity logging. | Use `caplog` to assert structured log payloads, rotation thresholds, and that sensitive data is redacted before emission. |

### Hard-to-Test Areas

- **Adapter integrations (`src/cli_multi_rapid/adapters/*`)** rely on external CLIs (git, pytest, aider). Achieving deterministic unit tests will require abstraction layers around subprocess calls and network I/O.
- **GUI terminal (`src/gui_terminal/*`)** depends on PyQt6 and websocket backends, making headless unit testing non-trivial. Snapshot-style tests or component-level integration tests should be pursued separately with a Qt test harness.
- **Workflow state services (`src/cli_multi_rapid/state/*`, `enterprise/*`)** have deep coupling to databases and metrics exporters; they will need fakes or contract tests against a lightweight persistence layer.

## PowerShell Coverage Gaps

| Script/Module | Current Issues | Proposed Test Scenarios |
| --- | --- | --- |
| `scripts/report_costs.ps1` | Top-level script executes immediately, preventing isolated testing of `Sum-Tokens`. | Refactor into a module exposing pure functions for token aggregation and cost calculation, then add Pester tests covering arrays, scalars, null inputs, and malformed JSON. |
| `scripts/cleanup_duplicates.ps1` / `cleanup_logs.ps1` | Destructive operations with no guard rails or tests. | Introduce dry-run switches and dependency injection for filesystem calls (`Test-Path`, `Copy-Item`, `Remove-Item`). Add Pester tests that simulate item discovery, backup creation, and error handling using `Mock`. |
| `.ai/scripts/*.ps1` orchestrators | No automated validation. | Add lightweight smoke tests ensuring required parameters and that generated commands include expected flags (use `Mock Invoke-WebRequest`, etc.). |

## Node.js Coverage Gaps

- `package.json` lacks a `test` script; no JS/TS test runner is configured. Recommended action is to introduce `vitest` or `jest` for any future web/UI assets and to emit JUnit + LCOV artifacts for parity with other languages.

## Additional Recommendations

1. **Stabilise legacy pytest suites.** Audit failing tests (especially `TestWorkflowRunner*`) and either align them with the current APIs or mark them with `@pytest.mark.xfail` plus rationale until feature parity is restored.
2. **Incremental coverage expansion.** Prioritise the security package (audit/framework/auth) and workflow orchestration modules, as they are core to the platform's reliability and governance.
3. **Adopt contract/integration environments.** For adapter and setup scripts, use dockerised fixtures or contract tests to validate interactions with external CLIs without hitting production systems.
4. **Document edge cases.** As new tests are added, capture assumptions and invariants in `docs/` so future contributors can extend coverage without reverse-engineering behaviour.

The new runner, configuration, and documentation in this change-set provide the scaffolding for these follow-up efforts.
