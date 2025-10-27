Set-StrictMode -Version Latest

Describe 'merge_to_mod path safety' {
  BeforeAll {
    $script:root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    $script:merge = Join-Path $script:root '.runs\merge_to_mod.ps1'
    . $script:merge
  }

  It 'sanitizes relative paths that escape base' {
    $base = 'C:\a\b\c'
    $full = 'C:\a\MCP_INTEGRATION.md'
    $rel = Get-RelPath -full $full -base $base
    $rel | Should -Be 'MCP_INTEGRATION.md'
    @($rel -split '[\\/]' | Where-Object { $_ -eq '..' }).Count | Should -Be 0

    $target = 'C:\target\module_MOD'
    $dest = Join-Path $target $rel
    $targetRoot = [System.IO.Path]::GetFullPath($target + [System.IO.Path]::DirectorySeparatorChar)
    $destFull = [System.IO.Path]::GetFullPath($dest)
    $destFull.StartsWith($targetRoot, [System.StringComparison]::OrdinalIgnoreCase) | Should -BeTrue
  }

  It 'preserves nested relative path inside base' {
    $tmp = New-Item -ItemType Directory -Path (Join-Path $env:TEMP ([Guid]::NewGuid()))
    $baseDir = Join-Path $tmp.FullName 'src'
    New-Item -ItemType Directory -Path (Join-Path $baseDir 'a\b') -Force | Out-Null
    $full = Join-Path $baseDir 'a\b\c.txt'
    Set-Content -Path $full -Value 'x' -Encoding utf8
    $rel = Get-RelPath -full $full -base $baseDir
    $rel | Should -Be 'a\\b\\c.txt'
    @($rel -split '[\\/]' | Where-Object { $_ -eq '..' }).Count | Should -Be 0
  }

  It 'normalizes dot segments' {
    $base = 'C:\a\b'
    $full = 'C:\a\b\.\c\.\file.txt'
    $rel = Get-RelPath -full $full -base $base
    $rel | Should -Be 'c\\file.txt'
  }
}

