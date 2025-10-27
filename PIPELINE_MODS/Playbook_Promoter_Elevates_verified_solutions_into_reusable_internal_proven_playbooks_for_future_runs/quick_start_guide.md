# Quick Start: Implement Streamlined Workflow in < 1 Hour

**Goal:** Get a working file-watcher pipeline with Python + PowerShell support in 45-60 minutes.

---

## Prerequisites (5 minutes)

### Install Tools

**PowerShell users:**
```powershell
# Install Invoke-Build
Install-Module -Name InvokeBuild -Scope CurrentUser -Force

# Install Python tools
pip install ruff pyright pytest bandit

# Install PowerShell tools
Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -Force
Install-Module -Name Pester -Scope CurrentUser -Force
```

**Python users:**
```bash
# Install pyinvoke
pip install invoke

# Install Python tools
pip install ruff pyright pytest bandit

# Install PowerShell (if not present)
# Linux/Mac: https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell

# Install PowerShell tools (from pwsh)
pwsh -Command "Install-Module PSScriptAnalyzer, Pester -Scope CurrentUser -Force"
```

---

## Step 1: Choose Your SSOT (2 minutes)

Pick one based on your team's primary language:

**Option A:** PowerShell-first (Invoke-Build)
- Use if: Windows/.NET/PowerShell dominant
- Benefits: Native incremental builds, better Windows integration

**Option B:** Python-first (pyinvoke)
- Use if: Cross-platform or Python-dominant
- Benefits: More Pythonic, easier to import as library

**For this guide, we'll show both. Pick one and skip the other sections.**

---

## Step 2: Create Directory Structure (1 minute)

```bash
# Create directories
mkdir -p watcher .runs/watch .runs/ci

# Create empty files
touch watcher/watch.config.json watcher/watch.ignore
touch .gitignore README.md CONTRIBUTING.md
```

---

## Step 3A: PowerShell Implementation (15 minutes)

### Create `build.ps1`

```powershell
# build.ps1 - Streamlined task runner
param([string]$Path, [switch]$Strict)

# ============================================================================
# ROUTING
# ============================================================================
function Get-Toolchain([string]$FilePath) {
    switch -Regex ($FilePath) {
        '\.(py)$'              { 'python' }
        '\.(ps1|psm1|psd1)$'   { 'powershell' }
        default                { 'unknown' }
    }
}

# ============================================================================
# PYTHON TASKS
# ============================================================================
task python.fix {
    exec { ruff format $Path }
    exec { ruff check --fix $Path }
}

task python.lint python.fix, {
    exec { ruff check $Path }
}

task python.types python.lint, {
    exec { pyright $Path }
}

task python.test python.types, {
    $module = [IO.Path]::GetFileNameWithoutExtension($Path)
    exec { pytest -k $module -v }
}

# ============================================================================
# POWERSHELL TASKS
# ============================================================================
task pwsh.fix {
    Invoke-ScriptAnalyzer -Path $Path -Fix
}

task pwsh.lint pwsh.fix, {
    $r = Invoke-ScriptAnalyzer -Path $Path
    if ($r) { throw "Lint failures: $($r.Count)" }
}

task pwsh.test pwsh.lint, {
    $testPath = $Path -replace '\.ps(m?)1$', '.Tests.ps$1'
    if (Test-Path $testPath) {
        $r = Invoke-Pester -Path $testPath -PassThru
        if ($r.FailedCount -gt 0) { throw "Tests failed" }
    }
}

# ============================================================================
# UNIVERSAL TASKS
# ============================================================================
task check.one {
    $toolchain = Get-Toolchain $Path
    $startTime = Get-Date
    
    try {
        switch ($toolchain) {
            'python' { Invoke-Build python.test -Result r }
            'powershell' { Invoke-Build pwsh.test -Result r }
            default { throw "Unknown toolchain: $Path" }
        }
        
        $result = @{
            timestamp = $startTime.ToString('o')
            file = $Path
            toolchain = $toolchain
            success = $r.Errors.Count -eq 0
            elapsed_ms = ((Get-Date) - $startTime).TotalMilliseconds
            steps = $r.Tasks | ForEach-Object {
                @{ name = $_.Name; success = $null -eq $_.Error }
            }
        }
    } catch {
        $result = @{
            timestamp = $startTime.ToString('o')
            file = $Path
            success = $false
            error = $_.Exception.Message
        }
    }
    
    # Write result
    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $result | ConvertTo-Json | Set-Content ".runs/watch/$timestamp.json"
    
    $status = if ($result.success) { "✓" } else { "✗" }
    "$timestamp | $status | $Path" | Add-Content .runs/watch/watch.log
    
    if (-not $result.success) { throw "Check failed" }
}

task dev {
    Get-ChildItem -Recurse -Include *.py,*.ps1 |
        Where-Object { $_.LastWriteTime -gt (Get-Date).AddHours(-1) } |
        ForEach-Object { Invoke-Build check.one -Path $_.FullName }
}

task ci {
    Get-ChildItem -Recurse -Include *.py,*.ps1,*.psm1 |
        ForEach-Object { Invoke-Build check.one -Path $_.FullName -Strict }
}
```

### Create `watcher/watch.ps1`

```powershell
# watcher/watch.ps1 - Minimal file watcher
param([int]$DebounceMs = 500)

$debounceMap = @{}
$config = Get-Content watcher/watch.config.json | ConvertFrom-Json
$ignore = Get-Content watcher/watch.ignore

$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = Get-Location
$watcher.IncludeSubdirectories = $true
$watcher.Filter = "*.*"

$onChange = {
    param($sender, $e)
    $path = $e.FullPath
    
    # Check ignore
    foreach ($pattern in $script:ignore) {
        if ($path -like $pattern) { return }
    }
    
    # Check extension
    if ($path -notmatch '\.(py|ps1|psm1)$') { return }
    
    # Debounce
    $now = Get-Date
    if ($script:debounceMap.ContainsKey($path)) {
        if (($now - $script:debounceMap[$path]).TotalMilliseconds -lt $script:DebounceMs) {
            return
        }
    }
    $script:debounceMap[$path] = $now
    
    # Stability check
    Start-Sleep -Milliseconds 100
    try {
        $stream = [IO.File]::Open($path, 'Open', 'Read', 'ReadWrite')
        $stream.Close()
    } catch { return }
    
    # Invoke check
    Write-Host "Checking: $path" -ForegroundColor Cyan
    Invoke-Build check.one -Path $path
}

Register-ObjectEvent $watcher 'Changed' -Action $onChange | Out-Null
Register-ObjectEvent $watcher 'Created' -Action $onChange | Out-Null

$watcher.EnableRaisingEvents = $true

Write-Host "Watching $(Get-Location) - Press Ctrl+C to stop" -ForegroundColor Green
try { while ($true) { Start-Sleep 1 } }
finally { $watcher.Dispose() }
```

### Test It (5 minutes)

```powershell
# Test single file check
Invoke-Build check.one -Path "some_script.py"

# Test dev loop
Invoke-Build dev

# Start watcher (in separate terminal)
.\watcher\watch.ps1

# Make changes to a .py or .ps1 file and save
# Watch the terminal for automatic checks!
```

---

## Step 3B: Python Implementation (15 minutes)

### Create `tasks.py`

```python
"""tasks.py - Streamlined task runner"""
from invoke import task, Collection, Exit
from pathlib import Path
import json
from datetime import datetime

# ============================================================================
# ROUTING
# ============================================================================
def get_toolchain(path: Path) -> str:
    suffix = path.suffix.lower()
    if suffix == '.py':
        return 'python'
    elif suffix in ['.ps1', '.psm1', '.psd1']:
        return 'powershell'
    return 'unknown'

# ============================================================================
# PYTHON TASKS
# ============================================================================
@task
def py_fix(c, path):
    c.run(f"ruff format {path}")
    c.run(f"ruff check --fix {path}")

@task(pre=[py_fix])
def py_lint(c, path):
    c.run(f"ruff check {path}")

@task(pre=[py_lint])
def py_types(c, path):
    c.run(f"pyright {path}")

@task(pre=[py_types])
def py_test(c, path):
    module = Path(path).stem
    c.run(f"pytest -k {module} -v")

# ============================================================================
# POWERSHELL TASKS
# ============================================================================
@task
def pwsh_fix(c, path):
    c.run(f'pwsh -Command "Invoke-ScriptAnalyzer -Path {path} -Fix"')

@task(pre=[pwsh_fix])
def pwsh_lint(c, path):
    c.run(f'pwsh -Command "Invoke-ScriptAnalyzer -Path {path}"')

@task(pre=[pwsh_lint])
def pwsh_test(c, path):
    test_path = str(Path(path).with_suffix('.Tests.ps1'))
    if Path(test_path).exists():
        c.run(f'pwsh -Command "Invoke-Pester -Path {test_path}"')

# ============================================================================
# UNIVERSAL TASKS
# ============================================================================
@task
def check_one(c, path):
    """Entry point for watcher"""
    file_path = Path(path)
    toolchain = get_toolchain(file_path)
    start_time = datetime.utcnow()
    
    result = {
        'timestamp': start_time.isoformat(),
        'file': str(path),
        'toolchain': toolchain,
        'success': True
    }
    
    try:
        if toolchain == 'python':
            py_test(c, str(file_path))
        elif toolchain == 'powershell':
            pwsh_test(c, str(file_path))
        else:
            raise ValueError(f"Unknown toolchain for: {path}")
    except Exception as e:
        result['success'] = False
        result['error'] = str(e)
    
    # Write result
    timestamp = datetime.utcnow().strftime('%Y%m%d_%H%M%S')
    out_path = Path(f".runs/watch/{timestamp}.json")
    out_path.parent.mkdir(parents=True, exist_ok=True)
    
    with open(out_path, 'w') as f:
        json.dump(result, f, indent=2)
    
    status = "✓" if result['success'] else "✗"
    with open('.runs/watch/watch.log', 'a') as f:
        f.write(f"{timestamp} | {status} | {path}\n")
    
    if not result['success']:
        raise Exit(f"Check failed for {path}")

@task
def dev(c):
    """Check recently changed files"""
    import subprocess
    recent = subprocess.run(
        ['git', 'diff', '--name-only', 'HEAD@{1.hour.ago}', 'HEAD'],
        capture_output=True, text=True
    ).stdout.strip().split('\n')
    
    for file in recent:
        if file.endswith(('.py', '.ps1', '.psm1')):
            check_one(c, file)

@task
def ci(c):
    """CI gate: check all files"""
    for pattern in ['**/*.py', '**/*.ps1', '**/*.psm1']:
        for file in Path('.').glob(pattern):
            if '.runs' not in str(file):
                check_one(c, str(file))

ns = Collection(check_one, dev, ci)
```

### Create `watcher/watch.py`

```python
#!/usr/bin/env python3
"""watch.py - Minimal file watcher"""
import time
import json
from pathlib import Path
from datetime import datetime, timedelta
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler
import subprocess

class Handler(FileSystemEventHandler):
    def __init__(self):
        with open('watcher/watch.config.json') as f:
            self.config = json.load(f)
        with open('watcher/watch.ignore') as f:
            self.ignore = [line.strip() for line in f if line.strip()]
        self.debounce_map = {}
        self.debounce_ms = self.config.get('debounce_ms', 500)
    
    def should_ignore(self, path: Path) -> bool:
        path_str = str(path)
        for pattern in self.ignore:
            if pattern in path_str:
                return True
        return path.suffix not in ['.py', '.ps1', '.psm1']
    
    def is_stable(self, path: Path) -> bool:
        try:
            with open(path, 'rb') as f:
                f.read(1)
            return True
        except:
            return False
    
    def process(self, src_path):
        path = Path(src_path)
        if self.should_ignore(path):
            return
        
        # Debounce
        now = datetime.now()
        if path in self.debounce_map:
            if (now - self.debounce_map[path]).total_seconds() * 1000 < self.debounce_ms:
                return
        self.debounce_map[path] = now
        
        # Stability
        time.sleep(0.1)
        if not self.is_stable(path):
            return
        
        # Check
        print(f"Checking: {path}")
        try:
            subprocess.run(['invoke', 'check-one', '--path', str(path)], check=True)
        except subprocess.CalledProcessError:
            pass
    
    def on_modified(self, event):
        self.process(event.src_path)
    
    def on_created(self, event):
        self.process(event.src_path)

if __name__ == '__main__':
    handler = Handler()
    observer = Observer()
    observer.schedule(handler, path='.', recursive=True)
    observer.start()
    
    print("Watching current directory (Ctrl+C to stop)")
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        observer.stop()
    observer.join()
```

### Install watchdog

```bash
pip install watchdog
```

### Test It (5 minutes)

```bash
# Test single file check
invoke check-one --path some_script.py

# Test dev loop
invoke dev

# Start watcher (in separate terminal)
python watcher/watch.py

# Make changes and save - watch automatic checks!
```

---

## Step 4: Configuration Files (10 minutes)

### `watcher/watch.config.json`

```json
{
  "debounce_ms": 500,
  "stability_check_ms": 100,
  "include_patterns": [
    "**/*.py",
    "**/*.ps1",
    "**/*.psm1"
  ]
}
```

### `watcher/watch.ignore`

```
.runs/
__pycache__/
.git/
*.tmp
*.swp
~*
```

### `pyproject.toml`

```toml
[tool.ruff]
line-length = 100
target-version = "py311"

[tool.ruff.lint]
select = ["E", "F", "I", "W"]
ignore = ["E501"]

[tool.pyright]
pythonVersion = "3.11"
typeCheckingMode = "basic"

[tool.pytest.ini_options]
testpaths = ["tests"]
```

### `PSScriptAnalyzer.psd1`

```powershell
@{
    Severity = @('Error', 'Warning')
    Rules = @{
        PSAvoidUsingCmdletAliases = @{ Enable = $true }
    }
}
```

### `.gitignore`

```
.runs/
__pycache__/
*.pyc
.pytest_cache/
.ruff_cache/
```

---

## Step 5: CI Integration (5 minutes)

### `.github/workflows/ci.yml`

**PowerShell version:**
```yaml
name: CI
on: [push, pull_request]

jobs:
  check:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-python@v4
        with:
          python-version: '3.11'
      
      - name: Install tools
        run: |
          pip install ruff pyright pytest
          Install-Module InvokeBuild, PSScriptAnalyzer, Pester -Force
      
      - name: Run CI
        run: Invoke-Build ci
      
      - uses: actions/upload-artifact@v3
        if: always()
        with:
          name: results
          path: .runs/ci/
```

**Python version:**
```yaml
name: CI
on: [push, pull_request]

jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-python@v4
        with:
          python-version: '3.11'
      
      - name: Install PowerShell
        run: |
          wget -q https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb
          sudo dpkg -i packages-microsoft-prod.deb
          sudo apt-get update
          sudo apt-get install -y powershell
      
      - name: Install tools
        run: |
          pip install invoke ruff pyright pytest watchdog
          pwsh -Command "Install-Module PSScriptAnalyzer, Pester -Force -Scope CurrentUser"
      
      - name: Run CI
        run: invoke ci
      
      - uses: actions/upload-artifact@v3
        if: always()
        with:
          name: results
          path: .runs/ci/
```

---

## Step 6: Documentation (5 minutes)

### `README.md`

```markdown
# Project Name

## Quick Start

### Install dependencies
```bash
# Python
pip install ruff pyright pytest invoke watchdog

# PowerShell
Install-Module InvokeBuild, PSScriptAnalyzer, Pester -Force
```

### Run checks

**PowerShell:**
```powershell
# Check single file
Invoke-Build check.one -Path script.ps1

# Dev loop (recent files)
Invoke-Build dev

# CI gate (all files)
Invoke-Build ci

# Start watcher
.\watcher\watch.ps1
```

**Python:**
```bash
# Check single file
invoke check-one --path script.py

# Dev loop
invoke dev

# CI gate
invoke ci

# Start watcher
python watcher/watch.py
```

### View results
```bash
# Results are in .runs/watch/
ls .runs/watch/*.json

# Human log
cat .runs/watch/watch.log
```
```

### `CONTRIBUTING.md`

```markdown
# Contributing

## Before Pushing

Always run the dev check:

**PowerShell:** `Invoke-Build dev`
**Python:** `invoke dev`

This runs fast checks on recently changed files.

## CI Expectations

Pull requests must pass `Invoke-Build ci` or `invoke ci`:
- ✅ All formatting applied
- ✅ No lint errors
- ✅ Types check
- ✅ Tests pass

## File Watcher

Start the watcher for instant feedback on save:

**PowerShell:** `.\watcher\watch.ps1`
**Python:** `python watcher/watch.py`

Results appear in `.runs/watch/`
```

---

## Step 7: Verify Everything Works (5 minutes)

### Create Test Files

**`test_sample.py`**
```python
def add(a: int, b: int) -> int:
    return a + b

def test_add():
    assert add(2, 3) == 5
```

**`test_sample.ps1`**
```powershell
function Get-Sum {
    param([int]$a, [int]$b)
    return $a + $b
}

# Test is in test_sample.Tests.ps1
```

**`test_sample.Tests.ps1`**
```powershell
Describe "Get-Sum" {
    It "adds two numbers" {
        Get-Sum 2 3 | Should -Be 5
    }
}
```

### Run Checks

**PowerShell:**
```powershell
# Check Python file
Invoke-Build check.one -Path test_sample.py

# Check PowerShell file
Invoke-Build check.one -Path test_sample.ps1

# Run dev (all recent)
Invoke-Build dev

# Start watcher and edit files
.\watcher\watch.ps1
```

**Python:**
```bash
# Check files
invoke check-one --path test_sample.py
invoke check-one --path test_sample.ps1

# Run dev
invoke dev

# Start watcher
python watcher/watch.py
```

### Verify Results

```bash
# Check results were written
ls .runs/watch/*.json

# View human log
cat .runs/watch/watch.log

# Should see entries like:
# 20250126_143022 | ✓ | test_sample.py
# 20250126_143025 | ✓ | test_sample.ps1
```

---

## Success Criteria Checklist

After 45-60 minutes, you should have:

- [x] Task runner (`build.ps1` or `tasks.py`) working
- [x] Watcher running and detecting saves
- [x] Results written to `.runs/watch/*.json`
- [x] Human log updated on each check
- [x] CI workflow committed
- [x] Documentation complete
- [x] Test files passing checks

---

## Troubleshooting

### Watcher not detecting changes

**Check:**
- Is the watcher running? (Should say "Watching...")
- Is the file extension included? (.py, .ps1, .psm1)
- Is the path ignored in `watch.ignore`?

**Debug:**
```powershell
# PowerShell: Add verbose output
Write-Host "Processing: $path" -ForegroundColor Yellow
```
```python
# Python: Add prints
print(f"Event detected: {src_path}")
```

### Task runner errors

**Check:**
- Are tools installed? (`ruff --version`, `pyright --version`)
- Is PowerShell accessible? (`pwsh --version`)
- Are paths correct? (Use absolute paths if needed)

**Debug:**
```powershell
# PowerShell: Run with verbose
Invoke-Build check.one -Path test.py -Verbose
```
```bash
# Python: Run with echo
invoke check-one --path test.py --echo
```

### Results not appearing

**Check:**
- Does `.runs/watch/` directory exist?
- Are there permission issues? (`ls -la .runs`)
- Is JSON valid? (`cat .runs/watch/*.json | jq`)

**Fix:**
```bash
# Recreate directory with correct permissions
rm -rf .runs
mkdir -p .runs/watch .runs/ci
chmod 755 .runs .runs/watch .runs/ci
```

---

## Next Steps

### Phase 2: Tune Performance (30-60 min)

1. **Adjust debounce timing** for your editor
   - Fast typers: increase to 800ms
   - Slow saves: decrease to 300ms

2. **Optimize test selection**
   - Add smarter module → test mapping
   - Skip slow tests in watch loop

3. **Add notifications** (optional)
   - Toast on Windows: `New-BurntToastNotification`
   - Desktop on Linux: `notify-send`

### Phase 3: Team Adoption (1-2 hours)

1. **Add pre-commit hook** (optional)
   ```bash
   # .git/hooks/pre-commit
   invoke check-one --path $STAGED_FILE
   ```

2. **Create dashboard** (optional)
   ```python
   # Simple web UI for .runs/watch/*.json
   python -m http.server --directory .runs
   ```

3. **Team training**
   - Demo the watcher
   - Show `.runs/watch/watch.log`
   - Practice `invoke dev` workflow

---

## Comparison to Original Blueprint

| Aspect | Original | Streamlined | You Did |
|--------|----------|-------------|---------|
| Setup time | 2-3 days | **45-60 min** | ✓ |
| Total files | 41 | **15** | ✓ |
| LOC (orchestration) | ~800 | **~150** | ✓ |
| Layers | 4 | **2** | ✓ |
| Latency | 2-4s | **1-2s** | ✓ |

**You just built a production-grade file-watcher pipeline in under an hour!**

---

## Resources

- **Invoke-Build:** https://github.com/nightroman/Invoke-Build
- **pyinvoke:** https://www.pyinvoke.org/
- **Ruff:** https://docs.astral.sh/ruff/
- **PSScriptAnalyzer:** https://github.com/PowerShell/PSScriptAnalyzer
- **watchdog:** https://python-watchdog.readthedocs.io/

---

## Support

Having issues? Check:
1. All tools installed? (`ruff --version`, etc.)
2. Correct paths? (Use `pwd` / `Get-Location`)
3. Permissions? (Can write to `.runs/`?)

Still stuck? Share:
- Your `build.ps1` or `tasks.py`
- Error messages
- Platform (Windows/Linux/Mac)
