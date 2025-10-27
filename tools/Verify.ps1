Set-StrictMode -Version Latest
$InformationPreference = 'Continue'
Write-Information 'Running PowerShell checks...'
if (Get-Command Invoke-ScriptAnalyzer -ErrorAction SilentlyContinue) {
  $pssaRoots = @()
  foreach ($cand in @('src','tools','scripts')) { if (Test-Path $cand) { $pssaRoots += $cand } }
  if ($pssaRoots.Count -gt 0) {
    foreach ($root in $pssaRoots) {
      Invoke-ScriptAnalyzer -Path $root -Recurse -Severity Error -EnableExit
    }
  } else {
    Write-Information 'No source roots (src/tools/scripts) detected; skipping PSScriptAnalyzer.'
  }
}
Write-Information 'Running Pester...'
if (Get-Command Invoke-Pester -ErrorAction SilentlyContinue) {
  $testRoots = @()
  if (Test-Path 'tests') { $testRoots += 'tests' }
  # Add other conventional folders as needed, but avoid templates and vendor content
  if ($testRoots.Count -gt 0) {
    Invoke-Pester -CI -Output Detailed -Path $testRoots
  } else {
    Write-Information 'No tests/ folder detected; skipping Pester.'
  }
}
Write-Information 'Running Python checks...'
$pythonRoots = @()
if (Test-Path 'pyproject.toml') { $pythonRoots += '.' }
if (Test-Path 'src') { $pythonRoots += 'src' }
if (Test-Path 'tests') { $pythonRoots += 'tests' }
if ($pythonRoots.Count -eq 0) {
  Write-Information 'No top-level Python project detected; skipping Python linters/tests.'
} else {
  $pyFiles = @()
  foreach ($root in $pythonRoots) {
    if (Test-Path $root) {
      $pyFiles += Get-ChildItem -Path $root -Recurse -Include *.py,*.pyi -File -ErrorAction SilentlyContinue
    }
  }
  if ($pyFiles.Count -eq 0) {
    Write-Information 'No Python files found; skipping Python linters/tests.'
  } else {
    if (Get-Command ruff -ErrorAction SilentlyContinue) { ruff check $pythonRoots ; if ($LASTEXITCODE) { exit $LASTEXITCODE } }
    if (Get-Command mypy -ErrorAction SilentlyContinue) { mypy $pythonRoots ; if ($LASTEXITCODE) { exit $LASTEXITCODE } }
    if (Get-Command pytest -ErrorAction SilentlyContinue) { pytest -q ; if ($LASTEXITCODE) { exit $LASTEXITCODE } }
  }
}
