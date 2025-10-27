# Module Registry

Modules catalog and usage.

## Registry Source

- All modules are registered in [`modules/registry.yaml`](./registry.yaml).
- Use `tools/nameguard/create_module.py --module <key>` to scaffold new modules once they appear in the registry.
- Registry entries require: `id` (Two-ID), `name`, `version` (SemVer), `owner`, and `dependencies`.

## Dependency Visualization

The Mermaid diagram below is generated from the registry via `Test-ModuleRegistry -Path modules/registry.yaml -MermaidOutputPath .runs/ci/graph.mmd`.

```mermaid
graph LR
  alerting_bridge["alerting_bridge (AL-3D7)"]
  analytics_core["analytics_core (AN-9Q4)"]
  domain_router["domain_router (DR-5K9)"]
  ingestion_hub["ingestion_hub (IN-7M2)"]
  alerting_bridge --> analytics_core
  alerting_bridge --> domain_router
  analytics_core --> ingestion_hub
  domain_router --> ingestion_hub
```

The rendered graph is also exported to [`.runs/ci/graph.mmd`](../.runs/ci/graph.mmd) for CI consumption.
