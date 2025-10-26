1) Build the GPT with the right guardrails

Create a Custom GPT and configure it with three things: Instructions, Knowledge, and (optional) Actions.

Where/how to do this: Open the GPT Builder, add your instructions, upload knowledge files, and choose capabilities (you don’t need Actions to start). 
OpenAI Help Center
+2
OpenAI Help Center
+2

Instructions (drop-in template)

Paste this into your GPT’s “Instructions” (modify the bullets to match your style):

Role: Senior PowerShell Engineer & QA.
Target runtimes: Windows PowerShell 5.1 and PowerShell 7.x.
Hard rules (never violate):

Generate idempotent scripts with Set-StrictMode -Version Latest and $ErrorActionPreference = 'Stop'.

Follow PSScriptAnalyzer rules; if a rule must be suppressed, justify it and use inline #pragma with a short rationale.

Write Pester tests for every function (positive, negative, edge).

Emit a release bundle with:

/src/*.ps1 scripts

/tests/*.Tests.ps1 Pester tests

PSScriptAnalyzerSettings.psd1 (custom rules/config)

Verify.ps1 (runs analyzer+tests and fails on any issue)

Output only two fenced blocks:

powershell # /src/*.ps1 and /tests/*.Tests.ps1 and Verify.ps1

powershell # PSScriptAnalyzerSettings.psd1

Before final output, run a self-check: list likely runtime issues (WinPS vs PS7, remoting/policy, path handling, encoding, ACLs), and show how the tests cover them.
Style: No aliases, clear parameter validation, comment-based help, transcript logging toggle, structured errors.
Assumptions checklist: Always ask/confirm: paths, required modules, elevation needs, network/UNC usage, and destructive actions.

Why this helps: It forces the model to produce the safety harness (tests + analyzer config) along with the script, and to think through pitfalls before “shipping.”

Knowledge files (upload to the GPT)

Upload small reference files so the GPT can cite and reuse them:

PSScriptAnalyzerSettings.psd1 (your baseline ruleset; start from Microsoft’s list and tweak) 
Microsoft Learn
+1

Pester.TestTemplates.ps1 (your preferred Describe/Context/It patterns) 
pester.dev
+2
pester.dev
+2

PowerShell.Conventions.md (your naming, error handling, logging, transcript, parameter sets, etc.)

WindowsRuntimeMatrix.md (anything special for 5.1 vs 7.x: modules available, encoding, path quirks)

(Optional) Snippets for common tasks you repeat (robust file IO, JSON schema validation, argument parsing).

Tip: The Help Center recommends explicit directions for knowledge usage (e.g., “Use PSScriptAnalyzerSettings.psd1 for rule IDs”), which improves adherence. 
OpenAI Help Center

(Optional) Actions

If you later want one-click CI integration, add a GPT Action that hits a tiny API you control (e.g., to open a PR or trigger a CI run). Start simple; OpenAI’s Actions docs cover auth, schema, and production notes. 
OpenAI Platform
+2
OpenAI Platform
+2

2) Make the GPT emit its own verification harness

Have the GPT always include a verification script and tests.

Verify.ps1 (generator rule)

Ask the GPT to always include and reference this runner:

# Verify.ps1
# Runs PSScriptAnalyzer and Pester. Fails the build on any issue.
param(
  [string]$Path = (Split-Path -Parent $PSCommandPath),
  [switch]$CI
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# Ensure modules
$modules = @('PSScriptAnalyzer','Pester')
foreach ($m in $modules) { if (-not (Get-Module -ListAvailable -Name $m)) { Install-Module $m -Scope CurrentUser -Force -ErrorAction Stop } }

# Static analysis
$settings = Join-Path $Path 'PSScriptAnalyzerSettings.psd1'
$analysis = Invoke-ScriptAnalyzer -Path (Join-Path $Path 'src') -Settings $settings -Recurse -Severity Error,Warning
if ($analysis) {
  $analysis | Format-Table RuleName,Severity,Message,ScriptName,Line,Column
  throw "PSScriptAnalyzer found $($analysis.Count) issues."
}

# Tests
$testResult = Invoke-Pester -Path (Join-Path $Path 'tests') -CI:$CI -FailedLineCount 20 -PassThru
if ($testResult.FailedCount -gt 0) { throw "Pester tests failed." }

Write-Host "✅ Analyzer clean and tests passed."


Why: You’ll run exactly the same checks locally/CI that the GPT optimizes against.

Docs: PSScriptAnalyzer rules and Pester usage. 
pester.dev
+3
Microsoft Learn
+3
Microsoft Learn
+3

3) Local workflow that pairs perfectly with the GPT
A. VS Code + PowerShell extension

You’ll get live linting from PSScriptAnalyzer while editing. 
Visual Studio Code

B. Add a pre-commit (optional but great)

Use the Python pre-commit framework (works on Windows). Add hooks:

Run pwsh -File Verify.ps1

Block commits if analyzer/test fail

Normalize line endings & UTF-8 BOM where needed

C. Minimal CI (GitHub Actions)

Have the GPT also generate a windows.yml workflow that:

Installs PowerShell 7 and 5.1 (or at least 7)

pwsh -File Verify.ps1 -CI

Uploads test results if you like

D. One-liner to validate locally
pwsh -File .\Verify.ps1

4) Prompt patterns that lower errors (use with your GPT)

Give your GPT tasks with explicit acceptance criteria and a self-review checklist:

Task framing: “Write a script to X. Must support PS5.1 and PS7. Detect and fail fast if prerequisites missing. Null-safe, path-safe, idempotent. Provide Pester tests and PSScriptAnalyzer settings.”

Red-team yourself: “List 10 ways this script could break in WinPS 5.1 vs PS7; show which test covers each risk; if uncovered, add tests.”

No hidden state: “Avoid $PWD assumptions; treat all paths as parameters; handle UNC; default to -WhatIf for destructive ops.”

Standards: “No aliases; strict mode; verbose logging option; comment-based help; parameter validation; consistent error records.”

This aligns with OpenAI’s guidance to be explicit, give examples, and leverage knowledge files. 
OpenAI Help Center

5) Starter files the GPT should reuse

Ask the GPT to regenerate or reuse these each time:

PSScriptAnalyzerSettings.psd1 (baseline)

@{
    ExcludeRules = @(
        # Keep tight. Only exclude with justification.
        # 'PSUseApprovedVerbs'    # Example: only if you truly must
    )
    Rules = @{
        PSUseApprovedVerbs = @{
            Enable = $true
        }
        PSAvoidUsingWriteHost = @{ Enable = $true }
        PSAvoidUsingConvertToSecureStringWithPlainText = @{ Enable = $true }
        PSUseConsistentWhitespace = @{ Enable = $true }
    }
}


(Review Microsoft’s rule catalog to tailor this to your preferences.) 
Microsoft Learn

tests/Example.Tests.ps1 (template)

Import-Module Pester
$here = Split-Path -Parent $PSCommandPath
. "$($here)/../src/<YourScript>.ps1"

Describe '<YourScript> core behavior' {
  Context 'Happy path' {
    It 'returns expected object' {
      $result = <Your-Function> -Param1 'x'
      $result | Should -Not -BeNullOrEmpty
    }
  }
  Context 'Error handling' {
    It 'throws on invalid input' {
      { <Your-Function> -Param1 $null } | Should -Throw
    }
  }
}


(You can keep a richer template in your knowledge files.) 
pester.dev

6) Day-to-day use (your 5-step loop)

Ask the GPT for a script or change set.

It returns /src, /tests, PSScriptAnalyzerSettings.psd1, and Verify.ps1.

Run locally: pwsh -File .\Verify.ps1

Fix anything the analyzer/tests flag (or have GPT patch them).

Commit only when green; CI double-checks.

Why this dramatically reduces errors

Static checks baked in: The GPT optimizes to satisfy PSScriptAnalyzer from the start. 
Microsoft Learn
+1

Executable specs: Pester tests catch regressions and environment edge cases before you run scripts on real data. 
pester.dev
+1

Determinism: Strict mode, explicit params, and self-review checklists reduce hidden assumptions (a major error source).

Repeatability: The same Verify.ps1 runs locally and in CI, so “works on my machine” goes away.

Good GPT hygiene: Using the Builder + knowledge files with explicit usage instructions is exactly how OpenAI recommends making reliable GPTs.