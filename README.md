# README.md

R_PIPELINE — AI-Operated Pipeline with Streamlined Watcher and Two-ID Modular Structure

This repository provides:
- A fast file watcher (watcher/)
- A Two-ID naming system with nameguard tooling (tools/nameguard/)
- A manifest-driven orchestrator (orchestrator/)
- 24 modular components scaffolded under modules/
- CI and documentation to prove and iterate the system

See CLAUDE.md for the full master plan and phases.

## Merge governance

- Merge policy: [.merge-policy.yaml](.merge-policy.yaml)
- Rerere guidance: [docs/merge/README.md](docs/merge/README.md)
- Merge train workflow: [docs/ci/merge-train.md](docs/ci/merge-train.md)

## Tooling guardrails

- Structured merge setup: [scripts/setup-merge-drivers.ps1](scripts/setup-merge-drivers.ps1)
- Worktree orchestration: [docs/workflows/worktrees.md](docs/workflows/worktrees.md)
- AI guardrails: [docs/ai/guardrails.md](docs/ai/guardrails.md)
- MCP overview: [docs/mcp/overview.md](docs/mcp/overview.md)

## Developer setup

- Windows: [docs/setup/windows.md](docs/setup/windows.md)
- Linux: [docs/setup/linux.md](docs/setup/linux.md)
- macOS: [docs/setup/macos.md](docs/setup/macos.md)
