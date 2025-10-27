```markdown
Naming convention (Two-ID)

Folder names:
  {module_key}_{TID}
  Example: ledger_LD-3X7

File names:
  {TID}.{role}.{ext}
  Examples:
    LD-3X7.run.py
    LD-3X7.config.yaml
    LD-3X7.schema.ledger.json
    LD-3X7.example.input.json

Roles:
  run: executable entrypoint for the module
  config: module configuration
  schema: JSON schema(s) for module I/O
  example.input: sample input for tests
  api.py: optional helper API surface
```