# AGENTS.md – 5‑Module Template Pack (PowerShell)

A ready‑to‑drop set of **agent instruction blocks** and **prompt templates** for generating high‑quality, deterministic PowerShell code using the **5 Module Categories**:

1) Data Acquisition  
2) Data Transformation  
3) State Change  
4) Configuration & Validation  
5) Orchestration

Each section includes: purpose, strict rules, inputs/outputs contract, acceptance criteria, Pester test template, and a prompt you can paste into your AI CLI (e.g., Codex CLI) to generate code.

---

## How to use this file

- **Pick a module category** → Copy the **Prompt Template** → Replace `{{placeholders}}` → Feed to your AI CLI.  
- **Generate tests first** where possible (especially for Transformation), then generate the function.  
- **Keep orchestration thin**; push logic into the other four categories.  
- **Require Pester tests** for every function.

> Suggested repo layout
```
Modules/<ModuleName>/
  Public/        # exported functions (ps1)
  Private/       # internal helpers (ps1)
  <ModuleName>.psd1
  <ModuleName>.psm1
Tests/<ModuleName>/
  Unit/
  Integration/
```

> Global conventions
- **Naming:** Verb‑Noun, PascalCase (e.g., `Get-`, `Convert-`, `Set-`, `Test-`, `Invoke-`).
- **Error handling:** Structured errors (`throw` only for unrecoverable), include `CategoryInfo`, `ErrorId`.
- **Logging:** Use `Write-Verbose`/`Write-Information` with `-InformationAction Continue`; no noisy default output.
- **Idempotence:**
  - Transformation: pure (no I/O; deterministic)
  - Acquisition: read‑only I/O
  - State Change: must support `-WhatIf/-Confirm` and detect drift before changing
- **Parameter binding:** Typed parameters; validate with attributes; no prompts in non‑interactive code.
- **Output:** Return **typed** `PSCustomObject`/class instances (don’t write strings unless explicitly a format cmdlet).

---

# 1) DATA ACQUISITION
**Goal:** Safely read external inputs (files, APIs, registries, databases) without mutating state.

### Rules
- No writes, no side effects (strictly read‑only).
- Implement **timeouts, retries, and backoff** for remote calls.
- Normalize outputs to a **documented schema** (typed properties, units, culture‑safe parsing).
- Parameterize sources (path/URI/credentials) and avoid hard‑coded locations.

### Inputs / Outputs Contract
- **Inputs:** `{{SourceType}}` (e.g., FilePath, Uri), auth (if needed), timeout settings.
- **Outputs:** Array of typed objects shaped by `{{OutputSchemaName}}`.

### Acceptance Criteria
- Returns no data on transient failure? → retries then **fails with helpful error**.
- Produces identical objects given the same source (deterministic normalization).
- Emits **no writes** and no hidden global state.

### Pester Test Template (Acquisition)
```powershell
Describe 'Get-{{Noun}} (Acquisition)' {
  Context 'Success path' {
    It 'returns typed objects matching schema' {
      $result = Get-{{Noun}} -Source {{Source}} -TimeoutSeconds 10
      $result | Should -Not -BeNullOrEmpty
      $result | ForEach-Object {
        $_ | Should -HaveProperty 'Id'
        $_ | Should -HaveProperty 'Name'
      }
    }
  }
  Context 'Timeouts and retries' {
    It 'retries and then throws a terminating error' {
      { Get-{{Noun}} -Source {{BadSource}} -TimeoutSeconds 1 } | Should -Throw
    }
  }
}
```

### Prompt Template (Acquisition → Copy/Paste)
```
You are a Senior PowerShell Engineer. Generate a **read-only Data Acquisition** function for module {{ModuleName}}.

Constraints:
- Function name: Get-{{Noun}}
- No writes/side effects; read-only I/O only
- Parameters: {{Parameters}} (typed, validated)
- Include timeout/retry/backoff (configurable)
- Normalize to schema {{OutputSchemaName}} with typed properties
- Use Write-Verbose/Information for diagnostics; no default noisy output
- Return array of typed PSCustomObject; no strings
- Include comment-based help and examples
- Add unit tests using Pester (use the test template in AGENTS.md)

Deliverables:
1) Public function file content (PowerShell)
2) Supporting Private helper(s) if needed
3) Pester unit tests covering success, retry, and error paths
```

---

# 2) DATA TRANSFORMATION
**Goal:** Pure logic; convert inputs to outputs with **no I/O**, **no side effects**.

### Rules
- Absolutely **pure** function(s): deterministic, referentially transparent.
- No `Get-Content`, no network calls, no registry; accept data in parameters only.
- Validate inputs; return typed objects; comprehensive unit tests over edge cases.

### Inputs / Outputs Contract
- **Inputs:** In‑memory objects conforming to `{{InputSchemaName}}`.
- **Outputs:** New objects conforming to `{{OutputSchemaName}}`.

### Acceptance Criteria
- Same inputs ⇒ same outputs; zero reliance on external state.
- Explicit error on invalid inputs; no silent coercions.

### Pester Test Template (Transformation)
```powershell
Describe 'Convert-{{Noun}} (Transformation)' {
  It 'maps input schema to output schema deterministically' {
    $input = @{ Id = 1; Name = 'X'; Value = 3 }
    $out = Convert-{{Noun}} -InputObject $input
    $out | Should -BeOfType PSCustomObject
    $out.Result | Should -Be 3
  }
  It 'rejects invalid inputs with clear errors' {
    { Convert-{{Noun}} -InputObject $null } | Should -Throw
  }
}
```

### Prompt Template (Transformation → Copy/Paste)
```
You are a Senior PowerShell Engineer. Generate a **pure Data Transformation** function for module {{ModuleName}}.

Constraints:
- Function name: Convert-{{Noun}}
- Pure function: no I/O, no global state, deterministic
- Parameters: -InputObject {{InputSchemaName}}
- Return: {{OutputSchemaName}} as typed PSCustomObject/class
- Validate inputs, throw on invalid
- Include comment-based help with input/output contracts
- Include comprehensive Pester unit tests (property invariants and edge cases)

Deliverables:
1) Function code
2) Pester tests
```

---

# 3) STATE CHANGE
**Goal:** Safely mutate external state (files, services, settings) with **idempotence** and `-WhatIf/-Confirm`.

### Rules
- `[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]`.
- Perform **pre‑checks** to detect current state and **skip** if already compliant.
- Support **`-WhatIf` and `-Confirm`**; **only change inside `if ($PSCmdlet.ShouldProcess())`**.
- Return a result object summarizing actions: `Before`, `After`, `Changed` (bool), `Details`.

### Inputs / Outputs Contract
- **Inputs:** Target spec (path/resource id), desired state parameters.
- **Outputs:** Typed result with fields `{ Target, Changed, Before, After, Messages }`.

### Acceptance Criteria
- Idempotent: second run with same desired state yields `Changed = $false`.
- Honors `-WhatIf`: no change occurs, but planned actions are described.

### Pester Test Template (State Change)
```powershell
Describe 'Set-{{Noun}} (StateChange)' {
  BeforeAll { Mock Test-Path { $true } }

  It 'supports -WhatIf and does not mutate' {
    Set-{{Noun}} -Target {{Target}} -Desired {{Spec}} -WhatIf | Out-Null
    # Validate no side effects via mocks/assertions
  }

  It 'is idempotent when desired state equals current state' {
    $r1 = Set-{{Noun}} -Target {{Target}} -Desired {{Spec}}
    $r2 = Set-{{Noun}} -Target {{Target}} -Desired {{Spec}}
    $r2.Changed | Should -BeFalse
  }
}
```

### Prompt Template (State Change → Copy/Paste)
```
You are a Senior PowerShell Engineer. Generate a **State Change** function for module {{ModuleName}}.

Constraints:
- Function name: Set-{{Noun}}
- Must include [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
- Implement idempotence: detect current vs desired state; skip when compliant
- All mutations guarded by: if ($PSCmdlet.ShouldProcess($Target, 'Set {{Noun}}')) { ... }
- Return typed result: Target, Changed(bool), Before, After, Messages
- Include comment-based help with examples (with and without -WhatIf)
- Provide Pester tests that verify -WhatIf and idempotence

Deliverables:
1) Function code
2) Any private helpers
3) Pester tests
```

---

# 4) CONFIGURATION & VALIDATION
**Goal:** Validate inputs, environment, and policy conformance; no mutation.

### Rules
- No writes; compute and return **validation results** with `Pass/Fail/Warning`.
- Prefer machine‑readable results: `{ RuleId, Level, Passed, Message, Evidence }`.
- May integrate with PSRule or custom rules; keep rule definitions declarative when possible.

### Inputs / Outputs Contract
- **Inputs:** Subject (object to validate) or environment context.
- **Outputs:** Array of validation result objects.

### Acceptance Criteria
- Every failure includes actionable `Message` and `Evidence`.
- Zero false positives on a clean subject (tune rules and thresholds).

### Pester Test Template (Validation)
```powershell
Describe 'Test-{{Noun}} (Validation)' {
  It 'returns Pass results for a compliant subject' {
    $subject = @{ Name='Good'; Enabled=$true }
    $results = Test-{{Noun}} -InputObject $subject
    ($results | Where-Object { -not $_.Passed }).Count | Should -Be 0
  }
  It 'returns Fail with evidence on non-compliance' {
    $subject = @{ Name='Bad'; Enabled=$false }
    $results = Test-{{Noun}} -InputObject $subject
    ($results | Where-Object Passed -eq $false).Count | Should -BeGreaterThan 0
  }
}
```

### Prompt Template (Validation → Copy/Paste)
```
You are a Senior PowerShell Engineer. Generate a **Configuration/Validation** function for module {{ModuleName}}.

Constraints:
- Function name: Test-{{Noun}}
- No writes; return array of result objects: RuleId, Level(Info|Warn|Error), Passed(bool), Message, Evidence
- Accept -InputObject {{SubjectSchemaName}}; support -Strict switch for tighter checks
- Include comment-based help explaining each rule
- Include Pester tests covering Pass/Fail/Warning scenarios

Deliverables:
1) Function code
2) Pester tests
```

---

# 5) ORCHESTRATION
**Goal:** Thin coordination that wires Acquisition → Transformation → Validation → StateChange. **No business logic** here; just flow, parameter passing, error routing, and logging.

### Rules
- Keep orchestration **stateless and minimal**; push logic into the four categories above.
- Honor `-WhatIf/-Confirm` **pass-through** to state‑changing steps.
- Structured logging at stage boundaries; fail fast with clear context.
- Return a run summary: `{ Succeeded, Steps:[{Name, Status, Artifacts}] }`.

### Inputs / Outputs Contract
- **Inputs:** Parameters to route to underlying functions (sources, options).
- **Outputs:** Execution summary + artifacts from each stage.

### Acceptance Criteria
- One switch enables dry-run across entire pipeline (WhatIf passthrough).
- Recoverable failures bubble up with stage/location context.

### Pester Test Template (Orchestration)
```powershell
Describe 'Invoke-{{Workflow}} (Orchestration)' {
  BeforeAll {
    Mock Get-{{Noun}} { @(@{ Id=1; Name='A' }) }
    Mock Convert-{{Noun}} { @{ Result=1 } }
    Mock Test-{{Noun}} { @(@{ RuleId='X'; Passed=$true; Level='Info'; Message='ok' }) }
    Mock Set-{{Noun}} { @{ Target='t'; Changed=$false; Before=@{}; After=@{} } }
  }
  It 'wires stages in order and returns a summary' {
    $summary = Invoke-{{Workflow}} -Source {{Source}} -WhatIf
    $summary.Steps.Count | Should -BeGreaterThan 0
    Assert-MockCalled Get-{{Noun}} -Times 1
    Assert-MockCalled Convert-{{Noun}} -Times 1
    Assert-MockCalled Test-{{Noun}} -Times 1
    Assert-MockCalled Set-{{Noun}} -Times 1
  }
}
```

### Prompt Template (Orchestration → Copy/Paste)
```
You are a Senior PowerShell Engineer. Generate an **Orchestration** function that composes existing category functions.

Constraints:
- Function name: Invoke-{{Workflow}}
- Sequence: Get-{{Noun}} → Convert-{{Noun}} → Test-{{Noun}} → Set-{{Noun}}
- Accept parameters for each stage and pass through WhatIf/Confirm to state changes
- Structured summary object: Succeeded, Steps[{Name, Status, Artifacts}], Errors
- Minimal logic; use try/catch per stage; log with Write-Information
- Include Pester tests mocking each stage and asserting call order

Deliverables:
1) Function code
2) Pester tests
```

---

## Agent Card Template (for Codex CLI)
Copy one card **per function** you want to generate.

```markdown
### Agent: {{Category}} → {{FunctionName}}

**Intent:** Generate {{Category}} function for module {{ModuleName}}.
**Inputs:** {{Inputs}}
**Outputs:** {{Outputs}}
**Constraints:** {{KeyRules}}
**Definition of Done:**
- ✅ Compiles on PowerShell 7+
- ✅ Pester tests provided and passing
- ✅ Typed parameters and outputs; comment‑based help with examples
- ✅ Deterministic behavior per category rules
- ✅ No side effects (except State Change within ShouldProcess)

**Prompt:**
<paste the relevant Prompt Template from this file with placeholders filled>
```

---

## Quick Checklists

**All functions**
- [ ] Verb‑Noun naming, comment‑based help
- [ ] Typed params with validation attributes
- [ ] Structured errors; no Write-Host
- [ ] Pester tests (happy, edge, error paths)

**Acquisition**
- [ ] Read‑only, timeout/retry/backoff
- [ ] Normalized schema output

**Transformation**
- [ ] Pure (no I/O), deterministic
- [ ] Comprehensive edge‑case tests

**State Change**
- [ ] Supports `-WhatIf/-Confirm`
- [ ] Idempotence: `Changed=$false` when already compliant

**Validation**
- [ ] Machine‑readable results with Evidence
- [ ] Clear rule docs

**Orchestration**
- [ ] Thin flow; mocks for all stages in tests
- [ ] WhatIf passthrough

---

## Notes for AI
- Prefer small, composable helpers in `Private/` over monoliths.
- Never hard‑code paths or secrets; accept via parameters or config.
- Avoid global variables and interactive prompts.
- Keep outputs pipeline‑friendly; return objects, not formatted strings.

