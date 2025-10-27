Set-StrictMode -Version Latest

Describe 'Test-ModuleRegistry' {
  BeforeAll {
    $repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
    $scriptPath = Join-Path $repoRoot 'tools/Test-ModuleRegistry.ps1'
    . $scriptPath
  }

  It 'fails when registry entry is missing required fields' {
    $invalidPath = Join-Path $TestDrive 'registry-invalid.yaml'
    @"
modules:
  - id: "DR-5K9"
    name: "domain_router"
    version: "1.0.0"
    dependencies: []
"@ | Set-Content -Path $invalidPath -Encoding utf8

    $result = Test-ModuleRegistry -Path $invalidPath

    $result.Pass | Should -BeFalse
    $result.Reasons | Should -Not -BeEmpty
    $result.Reasons | Should -Contain "Module 'domain_router' is missing required field 'owner'."
  }

  It 'passes for a valid registry and emits Mermaid output when requested' {
    $validPath = Join-Path $TestDrive 'registry-valid.yaml'
    @"
modules:
  - id: "DR-5K9"
    name: "domain_router"
    version: "1.0.0"
    owner: "Platform"
    dependencies:
      - "ingestion_hub"
  - id: "IN-7M2"
    name: "ingestion_hub"
    version: "1.1.0"
    owner: "Data"
    dependencies: []
"@ | Set-Content -Path $validPath -Encoding utf8

    $mermaidPath = Join-Path $TestDrive 'graph.mmd'
    $result = Test-ModuleRegistry -Path $validPath -MermaidOutputPath $mermaidPath

    $result.Pass | Should -BeTrue
    $result.Reasons | Should -BeEmpty
    Test-Path -Path $mermaidPath | Should -BeTrue
    (Get-Content -Path $mermaidPath -Raw) | Should -Match 'graph LR'
    $result.Mermaid | Should -Match 'domain_router'
    $result.Mermaid | Should -Match 'domain_router --> ingestion_hub'
  }
}
