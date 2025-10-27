 url=https://github.com/DICKY1987/R_PIPELINE/blob/main/modules/README.md
# modules/README.md

Modules catalog and usage.

- All modules are registered in modules/registry.yaml
- Use tools/nameguard/create_module.py --module <key> to scaffold
- Module layout:
  - {TID}.run.py
  - {TID}.config.yaml
  - {TID}.schema.json
  - api.py
  - README.md