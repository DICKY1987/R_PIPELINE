```markdown
# DEVELOPMENT

Contributing
- run nameguard checks locally: python tools/nameguard/nameguard.py --check
- scaffold a module: python tools/nameguard/create_module.py --module ledger
- run unit tests: python -m pytest

Adding a module
- Add entry to modules/registry.yaml
- Run create_module.py to scaffold files
- Implement {TID}.run.py and update manifests/modules_config.yaml
```