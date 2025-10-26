Quick Reference — Development Order
Timeline by Phase
Phase	When	Goal
0. Foundation & Analysis	Week 1	Codebase audit, module scaffolding, shared test infra, publishing pipeline. 

Modularization Phase Plan -Para…

 

Modularization Phase Plan -Para…

 

Modularization Phase Plan -Para…

 

Modularization Phase Plan -Para…

 

Modularization Phase Plan -Para…


1. Parallel Module Dev	Weeks 2–4	Build Streams A–G (PowerShell + MCP servers). 

Modularization Phase Plan -Para…


2. Integration & Wiring	Week 5	Wire modules, migrate scripts, integration tests. 

Modularization Phase Plan -Para…

 

Modularization Phase Plan -Para…

 

Modularization Phase Plan -Para…


3. CI/CD & Quality Gates	Week 6	Update GH Actions, hooks, full test runs. 

Modularization Phase Plan -Para…

 

Modularization Phase Plan -Para…

 

Modularization Phase Plan -Para…


4. Docs & Knowledge Transfer	Week 7	Module docs, training, retrospective. 

Modularization Phase Plan -Para…

 

Modularization Phase Plan -Para…

 

Modularization Phase Plan -Para…

Phase 0 — What can run in parallel

0.1 Audit, 0.2 Scaffolding, 0.3 Shared Testing → parallel

0.4 Publishing depends on 0.2 Scaffolding. 

Modularization Phase Plan -Para…

Phase 1 — Streams, Owners, Dependencies
Stream	Module	Category	Duration	Depends on	Notes
A	DataAcquisition.MCP	Data Acquisition	2 wks	—	Read-only getters, mocks, 80%+ cov. 

Modularization Phase Plan -Para…

 

Modularization Phase Plan -Para…


B	DataTransformation.MCP	Transformation	2 wks	—	Pure/idempotent, property-based tests. 

Modularization Phase Plan -Para…

 

Modularization Phase Plan -Para…


C	StateChange.MCP	State Change	2.5 wks	A	CUD, rollback, -WhatIf, 95%+ cov. 

Modularization Phase Plan -Para…

 

Modularization Phase Plan -Para…


D	Validation.MCP	Config/Validation	2.5 wks	A, B	Detect-only validators; OPA/JSON Schema. 

Modularization Phase Plan -Para…

 

Modularization Phase Plan -Para…


E	MCP Server Modules (Py/TS)	Mixed	3 wks	—	Independent; runs fully in parallel. 

Modularization Phase Plan -Para…

 

Modularization Phase Plan -Para…


F	Orchestration.SafePatch	Orchestration	2.5 wks	A, B, C, D	Pipeline orchestrator (format→policy). 

Modularization Phase Plan -Para…

 

Modularization Phase Plan -Para…


G	Orchestration.MCP	Orchestration	2 wks	A, B, C, D	Env init, drift detection, reports. 

Modularization Phase Plan -Para…

 

Modularization Phase Plan -Para…

Stream Dependency Map & Critical Path

Map: A → C; B → D; (A+B) → D → F → G; E is independent. 

Modularization Phase Plan -Para…

Critical Path: A/B → D → F → G (≈5 weeks). 

Modularization Phase Plan -Para…

Parallel sweet spots: A, B, E in Weeks 2–3. 

Modularization Phase Plan -Para…

Phase 2–4 — Integration, CI/CD, Docs (Order of operations)

Add RequiredModules & auto-loading, then migrate scripts to module calls, then integration tests. 

Modularization Phase Plan -Para…

 

Modularization Phase Plan -Para…

 

Modularization Phase Plan -Para…

Update CI workflows & pre-commit, then full suite & perf. 

Modularization Phase Plan -Para…

 

Modularization Phase Plan -Para…

 

Modularization Phase Plan -Para…

Ship module docs & training, then retro & roadmap. 

Modularization Phase Plan -Para…

 

Modularization Phase Plan -Para…

 

Modularization Phase Plan -Para…

Dependency Issues to Watch (and Mitigations)
Issue	Why it matters	Mitigation(s)
Module dependency hell	Complex RequiredModules chains can break builds.	Strict semver, constrained ranges, automated graph checks, lock files. 

Modularization Phase Plan -Para…


Breaking changes during migration	Parallel monolith→module cutover can regress.	Dual-run old/new in Phase 2, feature flags, integration tests, documented rollback. 

Modularization Phase Plan -Para…


Performance regressions	Modular boundaries can add overhead.	Benchmark before/after, profile load times, optimize hot paths, lazy-load. 

Modularization Phase Plan -Para…


Knowledge silos	Stream specialization can isolate know-how.	Cross-training, comprehensive docs, recorded sessions, pair programming. 

Modularization Phase Plan -Para…