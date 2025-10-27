Got it—here’s how to wire your **headless CLIs** into the pipeline so the **Python GUI** is just the control surface and status board.

# Big picture

* **Python GUI = conductor**: starts/halts runs, shows logs, toggles approvals, picks branches/targets, and renders the final diff/PR.
* **Headless CLIs = orchestra**: each tool owns a crisp slice of the pipeline; outputs are all machine-readable (JSON/patches), so modules can chain without prose.

# Division of labor (who does what—practical and non-overlapping)

## Source control & hosting

* **Git (git)**
  Use for: atomic worktrees/branches per work-stream, staging/committing generated edits, creating patch bundles.
  Strength to exploit: deterministic history and hooks; perfect for gating (pre-commit) and clean rollbacks (revert).
  Headless note: keep one ephemeral worktree per work-stream; enforce branch naming + locks to avoid races.

* **GitHub CLI (gh)**
  Use for: opening draft PRs from each work-stream, posting minimal CI triggers, fetching repo metadata, commenting machine summaries.
  Strength to exploit: first-class PR/issue/workflow ops; great “handoff” boundary from local synthesis → hosted review/CI.
  Headless note: store a PAT with least privileges; all outputs (PR URLs, run IDs) come back to the GUI for display.

## Coding/agent layer (plan → edit → commit)

* **Claude Code (CLI)**
  Use for: multi-file edits that need planning + reasoning (e.g., introduce an Invoke task suite, refactor modules).
  Strength to exploit: disciplined repo-wide changes + MCP integrations; solid at “plan→implement→commit” loops.
  Guardrail: always run inside a sandboxed worktree; require explicit approvals for shell/risky ops; cap file glob.

* **OpenAI Codex CLI**
  Use for: fast, local, file-scoped edits and script synthesis from structured specs (great for your “deliverables-first” templates).
  Strength to exploit: quick generation/rewrites when the desired shape is clear (fill in a known template).
  Guardrail: no repo admin; keep to file creation/edits; diff back to Git for review.

* **Gemini CLI**
  Use for: research+coding blends (e.g., pulling doc fragments, cross-checking examples, then emitting a concrete edit).
  Strength to exploit: strong web/tool use in a single loop; good at “prove with source, then patch.”
  Guardrail: disable auto-approve on commands; pipe outputs into your ledger, not straight to shell.

* **GitHub Copilot CLI**
  Use for: “explain this error,” “write the small helper,” “draft the test for this function,” and PR hygiene (titles/bodies).
  Strength to exploit: interactive terminal help + light edits; great filler between larger agent passes.
  Guardrail: do not grant broad tool access; keep it scoped to generation and git-safe actions.

* **Aider**
  Use for: targeted, reversible edits with tight git hygiene (auto-commits, easy undo), especially when you know exactly which files to touch.
  Strength to exploit: minimal context spillover; superb “surgical patch” tool.
  Guardrail: not a workflow runner; keep it in the “edit files, review diff, commit” lane.

## Verification & quality gates (script lanes only)

* **Python toolchain (headless)**: `ruff` / `pytest` (smoke), optional `mypy`
  Use for: static/quick runtime probes in the **Verifier** module. Strength: fast failure signals.
* **PowerShell toolchain (headless)**: `PSScriptAnalyzer` / `Pester` (smoke)
  Use for: PS script lanes’ static + test checks. Strength: first-party rules, consistent on Windows.

## Orchestration glue (what binds it)

* **Your Python GUI**
  Use for: selecting goal/branch, visualizing work-streams, per-tool approval toggles, live logs, diff preview, “Create PR” button.
  Strength to exploit: one place to see status across agents/tools; emits/consumes only JSON/patches; no direct editing.
  Headless note: GUI spawns subprocesses with structured stdout (JSONL); writes a single append-only `ledger.jsonl`.

# Where each tool slots into the pipeline modules

* **Plan Ingestor & Work-Stream Planner** → Python GUI + git worktrees (create branches, locks; no agents yet).
* **Domain Router** → GUI dispatch rules send ops to the right lane (python, powershell, workflow, config).
* **Discovery/Scoring (proven methods)** → Gemini/Claude/Codex can assist parsing docs, but prefer `gh` + custom fetchers for facts; agents summarize to JSON only.
* **Synthesizer & Structured Patcher** → Codex/Claude/Aider (pick based on scope):

  * file-scoped & templated ⇒ **Codex/Aider**
  * multi-file with refactors ⇒ **Claude Code**
* **Guardrails** → native linters/formatters (ruff, black, PSSA) run headless; agents only if a deterministic auto-fix fails to apply.
* **Verifier** → pytest/Pester smoke + short runtime probe; GUI streams results; agents stay idle here.
* **Selector & Exporter** → Git (stage/commit), then **gh** (draft PR) with a minimal machine summary; GUI shows PR link.
* **Ledger/Observability** → every tool writes JSON lines; GUI renders rollups (per work-stream timing, pass/fail, PR URL).

# Practical playbook (when to pick which agent)

* **Template filling / boilerplate generation** → *Codex CLI* (fast, cheap, deterministic diff).
* **Repo-wide change or multi-file coordination** → *Claude Code CLI* (planning + consistent edits).
* **Evidence gathering + justification snippets** → *Gemini CLI* (fetch + synthesize short machine notes).
* **Tiny fixes / test nits / PR wording** → *Copilot CLI*.
* **Pinpoint changes in known files** → *Aider* (safest diff discipline).

# Cross-cutting guardrails (make it safe headless)

* **Approvals matrix** per tool (read-only, write-files, run-cmd, network).
* **Sandbox per work-stream** (temp worktree, isolated venv, resource caps).
* **Single writer rule** per file (locks) + deterministic commit messages.
* **Everything machine-readable** (JSON/patch); no prose artifacts; GUI only shows diffs/status.

# What the user experiences in the GUI

* Pick goal/branch → see N parallel work-streams → watch logs tick by → inspect final diff → click “Create PR”.
* No agent chatter or long explanations—just **status, diffs, and PR link**.

This setup lets each CLI do exactly what it’s best at, keeps risk contained with branches + locks, and gives your GUI a clean, consistent surface to run the whole thing headlessly.
