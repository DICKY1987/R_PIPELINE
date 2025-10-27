MASTER PLAN_AI-Operated Pipeline with Streamlined Watcher_Two-ID Modular Structure
     
     Executive Summary
     
     Implement a complete AI-operated pipeline system that combines:
     1. Streamlined file-watcher (15 files, 3-4 hour setup)
     2. Modular 24-module structure with Two-ID naming
     3. Integration with existing SPEC-1 SafePatch infrastructure
     4. Proven-process discovery before custom coding
     5. Manifest-driven orchestration
     
     Total Timeline: 8 weeks with parallel workstreamsTeam Size: 2-3 developersIncremental Delivery: Working system after each phase
     
     ---
     PHASE 0: Foundation & Setup (Week 1)
     
     Goal: Establish base infrastructure and flatten directory structure
     
     Workstream 0A: Directory Restructuring (CRITICAL PATH)
     
     Owner: Dev 1Duration: 1 dayDependencies: None
     
     Tasks:
     1. ✅ Backup existing SPEC-1-AI-Upkeep-Suite-v2-Guardrails-MCP- directory
     2. ✅ Flatten nested SPEC-1.../SPEC-1... structure to single level
     3. ✅ Verify all existing scripts still work
     4. ✅ Update CLAUDE.md with new paths
     
     Deliverables:
     - Single-level SPEC-1 directory
     - Updated path references
     - Backup archive
     
     Workstream 0B: Create Base Directories (PARALLEL)
     
     Owner: Dev 2Duration: 2 hoursDependencies: None
     
     Tasks:
     1. ✅ Create /modules/ with phase subdirectories
     modules/
     ├── phase_0_backplane/
     ├── phase_1_intake_routing/
     ├── phase_2_discovery_scoring/
     ├── phase_3_synthesis_patch/
     ├── phase_4_quality_gates/
     ├── phase_5_decision_export/
     └── phase_6_knowledge_ci/
     2. ✅ Create /watcher/ directory
     3. ✅ Create /tools/nameguard/ directory
     4. ✅ Create /.runs/watch/ and /.runs/ci/ directories
     5. ✅ Create /manifests/ directory
     6. ✅ Create /orchestrator/ directory
     
     Deliverables:
     - Complete directory skeleton
     - .gitkeep files in empty dirs
     
     Workstream 0C: Registry Creation (PARALLEL)
     
     Owner: Dev 3Duration: 3 hoursDependencies: None
     
     Tasks:
     1. ✅ Create /modules/registry.yaml with all 24 modules
     2. ✅ Generate Two-IDs (mnemonic + hash) for each module
     3. ✅ Assign phase numbers and colors
     4. ✅ Add descriptions from chat transcripts
     5. ✅ Create /modules/NAMING_CONVENTION.md
     
     Deliverables:
     - Complete registry.yaml (24 modules)
     - Naming convention documentation
     - Color scheme for visualization
     
     Phase 0 Exit Criteria:
     - Single-level SPEC-1 directory
     - All base directories created
     - Registry.yaml complete with 24 modules
     - All existing SPEC-1 scripts still functional
     
     ---
     PHASE 1: Streamlined Watcher (Week 1-2)
     
     Goal: Get fast file-watching pipeline operational
     
     Workstream 1A: Watcher Core (CRITICAL PATH)
     
     Owner: Dev 1Duration: 1 dayDependencies: Phase 0 complete
     
     Tasks:
     1. ✅ Create /watcher/build.ps1 (Invoke-Build SSOT)
       - Extension routing (Python/PowerShell)
       - Task dependency chains
       - Result aggregation
       - Integration with SPEC-1 validation
     2. ✅ Create /watcher/watch.ps1 (File watcher)
       - FileSystemWatcher implementation
       - Debounce logic (500ms)
       - Stability checks
       - Invoke-Build integration
     3. ✅ Test single file check workflow
     
     Deliverables:
     - Working build.ps1 (150 lines)
     - Working watch.ps1 (60 lines)
     - Test results for sample files
     
     Workstream 1B: Watcher Configuration (PARALLEL)
     
     Owner: Dev 2Duration: 2 hoursDependencies: None
     
     Tasks:
     1. ✅ Create /watcher/watch.config.json
       - Debounce timing
       - Include/exclude patterns
       - Tool configurations
     2. ✅ Create /watcher/watch.ignore
       - Ignore patterns for .runs/, .git/, etc.
     3. ✅ Create /watcher/pyproject.toml
       - ruff, pyright, pytest configs
     4. ✅ Create /watcher/PSScriptAnalyzer.psd1
       - PowerShell linter rules
     5. ✅ Create /watcher/.gitignore
     6. ✅ Create /watcher/README.md
       - Quick start guide
       - Usage examples
     
     Deliverables:
     - 6 configuration files
     - Documentation
     
     Workstream 1C: Test Files & Validation (PARALLEL)
     
     Owner: Dev 3Duration: 2 hoursDependencies: Workstream 1A 50% complete
     
     Tasks:
     1. ✅ Create test_sample.py with tests
     2. ✅ Create test_sample.ps1 with tests
     3. ✅ Create test_sample.Tests.ps1 (Pester)
     4. ✅ Run manual validation
     5. ✅ Verify .runs/watch/*.json output
     6. ✅ Verify watch.log entries
     
     Deliverables:
     - Test files for both languages
     - Validation report
     
     Phase 1 Exit Criteria:
     - Watcher detects file saves
     - Routes correctly by extension
     - Calls existing SPEC-1 validation
     - Results written to .runs/watch/
     - Latency < 2 seconds
     - Both Python and PowerShell work
     
     ---
     PHASE 2: Two-ID Naming System (Week 2-3)
     
     Goal: Implement naming enforcement and module scaffolding
     
     Workstream 2A: Nameguard Tool (CRITICAL PATH)
     
     Owner: Dev 1Duration: 1.5 daysDependencies: Registry.yaml from Phase 0
     
     Tasks:
     1. ✅ Create /tools/nameguard/nameguard.py
       - Validate folder names: {module_key}_{TID}/
       - Validate file names: {TID}.{role}.{ext}
       - Registry lookup and verification
       - Scan and report functionality
     2. ✅ Create /tools/nameguard/nameguard.config.yaml
       - Patterns and rules
       - Allowed special files
       - Role definitions
     3. ✅ Add command-line interface
       - --check mode
       - --fix mode (auto-rename)
       - --generate-api mode
     4. ✅ Test validation on sample structures
     
     Deliverables:
     - Working nameguard.py (300 lines)
     - Configuration file
     - Test report
     
     Workstream 2B: Module Scaffolding Tool (PARALLEL)
     
     Owner: Dev 2Duration: 1 dayDependencies: Registry.yaml
     
     Tasks:
     1. ✅ Create /tools/nameguard/create_module.py
       - Read registry.yaml
       - Generate folder with TID
       - Create standard files:
           - {TID}.run.py
         - {TID}.config.yaml
         - {TID}.schema.contract.json
         - {TID}.example.input.json
         - api.py
         - __init__.py
         - README.md
     2. ✅ Add CLI interface
     3. ✅ Test module generation
     
     Deliverables:
     - create_module.py script
     - Sample generated module
     
     Workstream 2C: Pre-commit Integration (PARALLEL)
     
     Owner: Dev 3Duration: 4 hoursDependencies: Workstream 2A complete
     
     Tasks:
     1. ✅ Create .pre-commit-config.yaml
       - Hook for nameguard --check
       - Hook for existing SPEC-1 validation
     2. ✅ Create /scripts/hooks/nameguard-hook.sh
     3. ✅ Test pre-commit hooks
     4. ✅ Document in CONTRIBUTING.md
     
     Deliverables:
     - Pre-commit configuration
     - Hook scripts
     - Documentation
     
     Phase 2 Exit Criteria:
     - Nameguard validates naming convention
     - Create_module.py generates valid modules
     - Pre-commit hooks block invalid naming
     - All folders follow {module}__{TID} pattern
     - All files follow {TID}.{role}.{ext} pattern
     
     ---
     PHASE 3: Core Modules - Backplane (Week 3-4)
     
     Goal: Implement Phase 0 foundational modules
     
     Workstream 3A: Ledger Module (LD-3X7)
     
     Owner: Dev 1Duration: 2 daysDependencies: Phase 2 complete
     
     Tasks:
     1. ✅ Generate module: python create_module.py --module ledger
     2. ✅ Implement LD-3X7.run.py
       - Append-only JSONL writer
       - Cryptographic signatures
       - Query interface
     3. ✅ Create LD-3X7.schema.ledger.json
     4. ✅ Create example entries
     5. ✅ Write tests
     
     Deliverables:
     - Working ledger module
     - 10+ test cases
     
     Workstream 3B: Policy Pack Module (PP-9K2)
     
     Owner: Dev 2Duration: 2 daysDependencies: Phase 2 complete
     
     Tasks:
     1. ✅ Generate module: python create_module.py --module policy_pack
     2. ✅ Implement PP-9K2.run.py
       - Load OPA policies
       - Validate against schemas
       - Policy enforcement
     3. ✅ Integrate with existing /policy/opa/
     4. ✅ Write tests
     
     Deliverables:
     - Working policy module
     - Integration with SPEC-1 policies
     
     Workstream 3C: Cache/Rate-Limit Module (CR-4Y8)
     
     Owner: Dev 3Duration: 2 daysDependencies: Phase 2 complete
     
     Tasks:
     1. ✅ Generate module: python create_module.py --module cache_ratelimit
     2. ✅ Implement CR-4Y8.run.py
       - Simple file-based cache
       - Rate limiting logic
       - TTL management
     3. ✅ Write tests
     
     Deliverables:
     - Working cache/rate-limit module
     
     Workstream 3D: Concurrency Controller (CC-2Z5)
     
     Owner: Dev 1Duration: 1 dayDependencies: Workstream 3A complete
     
     Tasks:
     1. ✅ Generate module
     2. ✅ Implement file locking
     3. ✅ Implement work-stream isolation
     4. ✅ Write tests
     
     Deliverables:
     - Working concurrency module
     
     Workstream 3E: Observability Module (OB-6W1)
     
     Owner: Dev 2Duration: 1 dayDependencies: Workstream 3B complete
     
     Tasks:
     1. ✅ Generate module
     2. ✅ Implement metrics collection
     3. ✅ Implement JSONL logging
     4. ✅ Write tests
     
     Deliverables:
     - Working observability module
     
     Phase 3 Exit Criteria:
     - All 5 backplane modules operational
     - Each module has tests (>80% coverage)
     - Integration tests pass
     - Ledger capturing all events
     - Policies enforcing rules
     
     ---
     PHASE 4: Core Modules - Intake & Discovery (Week 4-5)
     
     Goal: Implement intake routing and discovery modules
     
     Workstream 4A: Intake Modules (5 modules)
     
     Owner: Dev 1 + Dev 2Duration: 3 daysDependencies: Phase 3 complete
     
     Parallel Tasks:
     
     Dev 1:
     1. ✅ Plan Ingestor (PI-5K9)
       - Parse ChangePlan JSON
       - Validate against schema
       - Normalize format
     2. ✅ Domain Router (DR-2QJ)
       - Route by file extension
       - Apply routing rules
       - Map to toolchains
     3. ✅ Query Expander (QE-8P4)
       - Expand search queries
       - Synonym handling
     
     Dev 2:
     1. ✅ Workstream Planner (WP-A2F)
       - Partition dependency graph
       - Create isolated work-streams
       - Manage locks
     2. ✅ Goal Normalizer (GN-7M3)
       - Normalize capability vocabulary
       - Map to canonical terms
     
     Deliverables:
     - 5 working intake/routing modules
     - Tests for each
     
     Workstream 4B: Discovery Modules (3 modules)
     
     Owner: Dev 3Duration: 3 daysDependencies: Phase 3 complete
     
     Tasks:
     1. ✅ Discovery Adapters (DA-1R6)
       - GitHub adapter
       - PyPI adapter
       - Docs site adapter
       - Rate limiting integration
     2. ✅ Feature Extractors (FE-3S8)
       - Extract license info
       - Extract activity metrics
       - Extract examples/docs
     3. ✅ Scorer (SC-4T9)
       - Load scoring profiles
       - Calculate scores
       - Rank candidates
       - Apply policy gates
     
     Deliverables:
     - 3 discovery modules
     - Proven-process workflow operational
     
     Phase 4 Exit Criteria:
     - All 8 modules (intake + discovery) operational
     - End-to-end workflow: ChangePlan → Discovery → Scores
     - Integration with cache and ledger
     - Tests pass (>80% coverage)
     
     ---
     PHASE 5: Synthesis & Quality Gates (Week 5-6)
     
     Goal: Implement code synthesis and validation
     
     Workstream 5A: Synthesis Modules (2 modules)
     
     Owner: Dev 1Duration: 3 daysDependencies: Phase 4 complete
     
     Tasks:
     1. ✅ Synthesizer (SY-5U1)
       - Template selection
       - Renderer for Python (Invoke)
       - Renderer for PowerShell (Invoke-Build)
       - Renderer for GitHub Actions
       - Integration with proven playbooks
     2. ✅ Structured Patcher (SP-6V2)
       - AST-aware Python patches
       - PowerShell structured edits
       - YAML/TOML patching
       - JSON Patch (RFC 6902)
     
     Deliverables:
     - 2 synthesis modules
     - Template library
     - Patch examples
     
     Workstream 5B: Quality Gate Modules (3 modules)
     
     Owner: Dev 2 + Dev 3Duration: 3 daysDependencies: Phase 4 complete
     
     Parallel Tasks:
     
     Dev 2:
     1. ✅ Guardrails (GR-7W3)
       - Pre-validation checks
       - Schema validation
       - Policy enforcement
       - Integration with SPEC-1 guardrails
     2. ✅ Verifier (VR-8X4)
       - Call existing SPEC-1 SafePatch
       - Format → Lint → Type → Test chain
       - Result aggregation
     
     Dev 3:
     1. ✅ Error Auto-Repair (ER-9Y5)
       - Common error patterns
       - Auto-fix strategies
       - Retry logic
     
     Deliverables:
     - 3 quality gate modules
     - Integration with watcher
     - Full SafePatch validation
     
     Phase 5 Exit Criteria:
     - All 5 modules operational
     - End-to-end: Discovery → Synthesis → Patch → Validate
     - Integration with existing SPEC-1 validation
     - Watcher can trigger full pipeline
     
     ---
     PHASE 6: Decision & Export (Week 6-7)
     
     Goal: Implement selection and artifact export
     
     Workstream 6A: Decision Modules (3 modules)
     
     Owner: Dev 1Duration: 2 daysDependencies: Phase 5 complete
     
     Tasks:
     1. ✅ Selector (SL-1Z6)
       - Champion selection logic
       - Comparison algorithms
       - Rationale generation
     2. ✅ Exporter (EX-2A7)
       - Export to /out/champions/
       - Generate patch files
       - Create PRs via gh CLI
     3. ✅ Provenance & Rollback (PR-3B8)
       - Provenance tracking
       - Rollback capability
       - Audit trail
     
     Deliverables:
     - 3 decision modules
     - Export workflow operational
     
     Workstream 6B: Knowledge & CI Modules (3 modules)
     
     Owner: Dev 2 + Dev 3Duration: 2 daysDependencies: Phase 5 complete
     
     Parallel Tasks:
     
     Dev 2:
     1. ✅ Knowledge Reuse (KR-4C9)
       - Store proven solutions
       - Query by capability
       - Promote to playbooks
     
     Dev 3:
     1. ✅ Playbook Promoter (PB-5D1)
       - Validate playbook quality
       - Promote to /proven-playbooks/
     2. ✅ CI/Pre-commit Integrator (CI-6E2)
       - Generate .github/workflows/
       - Generate pre-commit hooks
       - Integration scripts
     
     Deliverables:
     - 3 knowledge/CI modules
     - Proven playbooks library
     - CI integration
     
     Phase 6 Exit Criteria:
     - All 6 modules operational
     - Full pipeline: Intake → Discover → Synth → Validate → Export
     - Playbooks being promoted
     - CI/pre-commit auto-generation
     
     ---
     PHASE 7: Orchestrator & Integration (Week 7-8)
     
     Goal: Manifest-driven orchestration and full integration
     
     Workstream 7A: Manifest System (CRITICAL PATH)
     
     Owner: Dev 1Duration: 3 daysDependencies: All modules from Phases 3-6
     
     Tasks:
     1. ✅ Create /manifests/pipeline.yml
       - Define all 24 modules
       - Dependency graph
       - Phase organization
       - Configuration references
     2. ✅ Create /manifests/pipeline.schema.json
       - JSON Schema for pipeline.yml
       - Validation rules
     3. ✅ Create /manifests/modules_config.yaml
       - Per-module configurations
       - Override defaults
     
     Deliverables:
     - Complete pipeline.yml
     - Schema validation
     - Configuration system
     
     Workstream 7B: Orchestrator (CRITICAL PATH)
     
     Owner: Dev 2Duration: 3 daysDependencies: Workstream 7A 50% complete
     
     Tasks:
     1. ✅ Create /orchestrator/run.py
       - Read pipeline.yml
       - Execute dependency graph
       - Handle errors gracefully
       - Integrate with ledger
     2. ✅ Create /orchestrator/io_bus.py
       - JSONL module chaining
       - Input/output validation
       - Schema enforcement
     3. ✅ Create /orchestrator/graph_executor.py
       - Dependency-aware execution
       - Parallel execution where possible
       - Progress tracking
     4. ✅ Create /orchestrator/config.yaml
       - Global settings
       - Timeouts and limits
     
     Deliverables:
     - Working orchestrator
     - Manifest-driven execution
     - Parallel workstream support
     
     Workstream 7C: Watcher Integration (PARALLEL)
     
     Owner: Dev 3Duration: 2 daysDependencies: Workstream 7B 50% complete
     
     Tasks:
     1. ✅ Update /watcher/build.ps1
       - Call orchestrator for complex workflows
       - Call modules directly for simple checks
       - Result aggregation
     2. ✅ Create integration tests
     3. ✅ Performance tuning
     4. ✅ Update documentation
     
     Deliverables:
     - Integrated watcher + orchestrator
     - Performance benchmarks
     
     Workstream 7D: GUI Control Surface (OPTIONAL)
     
     Owner: Dev 3Duration: 2 daysDependencies: Phase 6 complete
     
     Tasks:
     1. ✅ Create /gui/app.py
       - Simple web interface
       - Work-stream status
       - Diff viewer
       - PR links
     2. ✅ Create /gui/api.py
       - IPC to orchestrator
       - Query ledger
       - Control execution
     
     Deliverables:
     - Optional GUI for monitoring
     
     Phase 7 Exit Criteria:
     - Orchestrator executes manifest-driven pipelines
     - All 24 modules integrated
     - Watcher + orchestrator working together
     - End-to-end workflow operational
     - Performance acceptable (<5s for simple checks)
     
     ---
     PHASE 8: Documentation & Polish (Week 8)
     
     Goal: Complete documentation and prepare for production
     
     Workstream 8A: Documentation
     
     Owner: All devsDuration: 2 daysDependencies: Phase 7 complete
     
     Tasks:
     1. ✅ Update /CLAUDE.md (root)
       - Complete system overview
       - Quick start guide
       - Module reference
       - Troubleshooting
     2. ✅ Update /modules/README.md
       - Module catalog
       - Two-ID reference
       - Phase descriptions
     3. ✅ Create /docs/ARCHITECTURE.md
       - System architecture
       - Data flow diagrams
       - Integration points
     4. ✅ Create /docs/DEVELOPMENT.md
       - Development workflow
       - How to add modules
       - Testing guidelines
     5. ✅ Update existing SPEC-1 CLAUDE.md
       - Integration notes
       - Cross-references
     
     Deliverables:
     - Complete documentation suite
     
     Workstream 8B: Testing & Validation
     
     Owner: All devsDuration: 2 daysDependencies: Phase 7 complete
     
     Tasks:
     1. ✅ Integration tests for all modules
     2. ✅ End-to-end workflow tests
     3. ✅ Performance benchmarking
     4. ✅ Load testing
     5. ✅ Security review
     6. ✅ Validate all schemas
     7. ✅ Run nameguard on entire codebase
     
     Deliverables:
     - Test suite (>80% coverage)
     - Performance report
     - Security audit report
     
     Workstream 8C: CI/CD Setup
     
     Owner: Dev 1Duration: 1 dayDependencies: Workstream 8B complete
     
     Tasks:
     1. ✅ Create .github/workflows/watcher-ci.yml
     2. ✅ Create .github/workflows/modules-ci.yml
     3. ✅ Create .github/workflows/integration-ci.yml
     4. ✅ Set up branch protection
     5. ✅ Configure CODEOWNERS
     
     Deliverables:
     - Complete CI/CD pipeline
     - Branch protection rules
     
     Phase 8 Exit Criteria:
     - All documentation complete
     - All tests passing (>80% coverage)
     - CI/CD operational
     - System ready for production use
     
     ---
     FINAL DIRECTORY STRUCTURE
     
     C:\Users\Richard Wilks\R_PIPELINE\
     │
     ├── CLAUDE.md                                   (Master guide)
     ├── README.md                                   (Project overview)
     │
     ├── modules/                                    (24 modules with Two-IDs)
     │   ├── registry.yaml                           (Single source of truth)
     │   ├── NAMING_CONVENTION.md
     │   ├── README.md
     │   │
     │   ├── phase_0_backplane/
     │   │   ├── ledger_LD-3X7/
     │   │   │   ├── LD-3X7.run.py
     │   │   │   ├── LD-3X7.config.yaml
     │   │   │   ├── LD-3X7.schema.ledger.json
     │   │   │   ├── LD-3X7.example.input.json
     │   │   │   ├── api.py
     │   │   │   ├── __init__.py
     │   │   │   └── README.md
     │   │   ├── policy_pack_PP-9K2/
     │   │   ├── cache_ratelimit_CR-4Y8/
     │   │   ├── concurrency_controller_CC-2Z5/
     │   │   └── observability_OB-6W1/
     │   │
     │   ├── phase_1_intake_routing/
     │   │   ├── plan_ingestor_PI-5K9/
     │   │   ├── workstream_planner_WP-A2F/
     │   │   ├── domain_router_DR-2QJ/
     │   │   ├── goal_normalizer_GN-7M3/
     │   │   └── query_expander_QE-8P4/
     │   │
     │   ├── phase_2_discovery_scoring/
     │   │   ├── discovery_adapters_DA-1R6/
     │   │   ├── feature_extractors_FE-3S8/
     │   │   └── scorer_SC-4T9/
     │   │
     │   ├── phase_3_synthesis_patch/
     │   │   ├── synthesizer_SY-5U1/
     │   │   └── structured_patcher_SP-6V2/
     │   │
     │   ├── phase_4_quality_gates/
     │   │   ├── guardrails_GR-7W3/
     │   │   ├── verifier_VR-8X4/
     │   │   └── error_auto_repair_ER-9Y5/
     │   │
     │   ├── phase_5_decision_export/
     │   │   ├── selector_SL-1Z6/
     │   │   ├── exporter_EX-2A7/
     │   │   └── provenance_rollback_PR-3B8/
     │   │
     │   └── phase_6_knowledge_ci/
     │       ├── knowledge_reuse_KR-4C9/
     │       ├── playbook_promoter_PB-5D1/
     │       └── ci_precommit_integrator_CI-6E2/
     │
     ├── watcher/                                    (Streamlined watcher)
     │   ├── build.ps1                               (Invoke-Build SSOT)
     │   ├── watch.ps1                               (File watcher)
     │   ├── watch.config.json
     │   ├── watch.ignore
     │   ├── pyproject.toml
     │   ├── PSScriptAnalyzer.psd1
     │   ├── .gitignore
     │   └── README.md
     │
     ├── orchestrator/                               (Manifest-driven)
     │   ├── run.py                                  (Main orchestrator)
     │   ├── io_bus.py                               (JSONL chaining)
     │   ├── graph_executor.py                       (Dependency execution)
     │   ├── config.yaml
     │   └── errors.py
     │
     ├── manifests/                                  (Pipeline definitions)
     │   ├── pipeline.yml                            (Single source of truth)
     │   ├── pipeline.schema.json                    (Validation)
     │   └── modules_config.yaml                     (Per-module config)
     │
     ├── tools/                                      
     │   └── nameguard/                              (Naming enforcement)
     │       ├── nameguard.py                        (Validator)
     │       ├── nameguard.config.yaml
     │       ├── create_module.py                    (Scaffolding)
     │       └── README.md
     │
     ├── SPEC-1-AI-Upkeep-Suite-v2-Guardrails-MCP/   (Existing - integrated)
     │   ├── .mcp/                                   (MCP servers)
     │   ├── mcp-servers/
     │   ├── policy/                                 (OPA policies)
     │   ├── scripts/validation/                     (SafePatch)
     │   ├── tools/                                  (Quality tools)
     │   └── templates/
     │
     ├── .research/                                  (Proven-process discovery)
     │   ├── research.config.yaml
     │   ├── queries.yaml
     │   ├── evidence.jsonl
     │   ├── ranked_candidates.json
     │   ├── decision.md
     │   ├── summary.md
     │   ├── cache/
     │   └── schema/
     │
     ├── proven-playbooks/                           (Proven solutions)
     │   ├── file_watch_lint_test.yaml
     │   ├── invoke_tasks.yaml
     │   └── gha_ci_pipeline.yaml
     │
     ├── out/                                        (Artifacts)
     │   ├── champions/                              (Selected solutions)
     │   └── patches/                                (Generated patches)
     │
     ├── .runs/                                      (Execution logs)
     │   ├── watch/                                  (Watcher results)
     │   ├── ci/                                     (CI results)
     │   └── orchestrator/                           (Pipeline runs)
     │
     ├── ._machine/                                  (Global ledger)
     │   ├── ledger.jsonl                            (Append-only)
     │   ├── cache/
     │   └── runs/
     │
     ├── gui/                                        (Optional UI)
     │   ├── app.py
     │   ├── api.py
     │   └── views/
     │
     ├── docs/                                       (Documentation)
     │   ├── ARCHITECTURE.md
     │   ├── DEVELOPMENT.md
     │   ├── MODULE_REFERENCE.md
     │   └── TROUBLESHOOTING.md
     │
     └── .github/                                    (CI/CD)
         └── workflows/
             ├── watcher-ci.yml
             ├── modules-ci.yml
             ├── integration-ci.yml
             └── quality.yml
     
     ---
     WORKSTREAM DEPENDENCIES CHART
     
     PHASE 0 (Week 1):
     ├─ 0A: Dir Restructuring [CRITICAL]
     ├─ 0B: Base Directories [PARALLEL]
     └─ 0C: Registry Creation [PARALLEL]

     PHASE 1 (Week 1-2):
     ├─ 1A: Watcher Core [CRITICAL, depends on 0A]
     ├─ 1B: Watcher Config [PARALLEL]
     └─ 1C: Test & Validation [depends on 1A 50%]

     PHASE 2 (Week 2-3):
     ├─ 2A: Nameguard [CRITICAL, depends on 0C]
     ├─ 2B: Module Scaffolding [PARALLEL, depends on 0C]
     └─ 2C: Pre-commit [depends on 2A]

     PHASE 3 (Week 3-4):
     ├─ 3A: Ledger [depends on 2B]
     ├─ 3B: Policy [PARALLEL, depends on 2B]
     ├─ 3C: Cache/Rate [PARALLEL, depends on 2B]
     ├─ 3D: Concurrency [depends on 3A]
     └─ 3E: Observability [depends on 3B]

     PHASE 4 (Week 4-5):
     ├─ 4A: Intake Modules (5) [depends on 3]
     └─ 4B: Discovery Modules (3) [PARALLEL, depends on 3]

     PHASE 5 (Week 5-6):
     ├─ 5A: Synthesis (2) [depends on 4]
     └─ 5B: Quality Gates (3) [PARALLEL, depends on 4]

     PHASE 6 (Week 6-7):
     ├─ 6A: Decision (3) [depends on 5]
     └─ 6B: Knowledge/CI (3) [PARALLEL, depends on 5]

     PHASE 7 (Week 7-8):
     ├─ 7A: Manifest [CRITICAL, depends on 6]
     ├─ 7B: Orchestrator [CRITICAL, depends on 7A 50%]
     ├─ 7C: Integration [depends on 7B 50%]
     └─ 7D: GUI [OPTIONAL, PARALLEL]

     PHASE 8 (Week 8):
     ├─ 8A: Documentation [ALL]
     ├─ 8B: Testing [ALL]
     └─ 8C: CI/CD [depends on 8B]
     
     ---
     KEY METRICS & SUCCESS CRITERIA
     
     Performance Targets
     
     - Watcher latency: < 2 seconds (simple check)
     - Full pipeline: < 30 seconds (discovery → synthesis)
     - Module startup: < 500ms
     - Orchestrator overhead: < 1 second
     
     Quality Targets
     
     - Test coverage: > 80% for all modules
     - Nameguard validation: 100% pass
     - Schema validation: 100% pass
     - CI success rate: > 95%
     
     Scalability Targets
     
     - Support 100+ files in repository
     - Handle 10+ concurrent work-streams
     - Process 1000+ discovery candidates
     - Store 10k+ ledger entries
     
     ---
     RISK MITIGATION
     
     Critical Path Risks
     
     1. Directory restructuring breaks SPEC-1
       - Mitigation: Full backup before Phase 0
       - Rollback plan documented
     2. Watcher performance issues
       - Mitigation: Performance benchmarking in Phase 1
       - Optimization buffer in schedule
     3. Module integration complexity
       - Mitigation: Integration tests throughout
       - Incremental delivery per phase
     4. Orchestrator scalability
       - Mitigation: Parallel workstream design
       - Performance testing in Phase 7
     
     ---
     DELIVERABLES SUMMARY
     
     After Phase 1 (Week 2):
     
     ✅ Working file-watcher with SPEC-1 integration
     
     After Phase 3 (Week 4):
     
     ✅ 5 backplane modules operational
     ✅ Ledger capturing events
     ✅ Policies enforced
     
     After Phase 4 (Week 5):
     
     ✅ Proven-process discovery working
     ✅ 13 modules operational
     
     After Phase 6 (Week 7):
     
     ✅ All 24 modules operational
     ✅ End-to-end pipeline working
     
     After Phase 8 (Week 8):
     
     ✅ Production-ready system
     ✅ Complete documentation
     ✅ CI/CD operational
     
     ---
     TEAM ALLOCATION
     
     Dev 1 (Senior, PowerShell/Python):
     - Critical path workstreams
     - Orchestrator development
     - Complex integrations
     
     Dev 2 (Mid-level, Python):
     - Module development
     - Policy integration
     - Testing
     
     Dev 3 (Mid-level, Python/JS):
     - Discovery modules
     - GUI (optional)
     - Documentation