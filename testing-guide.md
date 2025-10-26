# Testing Guide

## Overview

This guide covers testing practices, patterns, and infrastructure for the CLI Orchestrator project. We maintain ≥85% test coverage and enforce quality gates in CI/CD.

## Test Structure

```
tests/
├── conftest.py              # Shared fixtures and configuration
├── unit/                    # Unit tests for individual components
│   ├── adapters/           # Adapter unit tests
│   ├── coordination/       # Coordination logic tests
│   └── validation/         # Validation tests
├── integration/            # Integration tests
│   ├── conftest.py        # Integration-specific fixtures
│   ├── workflows/         # Workflow execution tests
│   └── fixtures/          # Test data and setup
└── e2e/                    # End-to-end tests
```

## Running Tests

### Basic Test Execution

```bash
# Run all tests
pytest

# Run with coverage
pytest --cov=src --cov-report=html

# Run specific test file
pytest tests/unit/adapters/test_base_adapter.py

# Run tests matching pattern
pytest -k "test_workflow"
```

### Test Categories

Tests are organized with markers:

```bash
# Run only unit tests
pytest -m unit

# Run only integration tests
pytest -m integration

# Exclude slow tests
pytest -m "not slow"

# Run security tests
pytest -m security
```

## Writing Tests

### Unit Test Example

```python
import pytest
from src.cli_multi_rapid.adapters.base_adapter import BaseAdapter, AdapterResult

def test_adapter_execution(mock_adapters):
    """Test adapter executes successfully."""
    adapter = mock_adapters['mock_deterministic']

    step = {
        'id': '1.001',
        'actor': 'mock_deterministic',
        'with': {'param': 'value'}
    }

    result = adapter.execute(step)

    assert result.success is True
    assert result.tokens_used == 0
    assert len(result.artifacts) > 0
```

### Integration Test Example

```python
import pytest

@pytest.mark.integration
async def test_workflow_execution(workflow_file, test_service):
    """Test complete workflow execution."""
    from src.cli_multi_rapid.workflow_runner import WorkflowRunner

    runner = WorkflowRunner()
    result = await runner.run_workflow(str(workflow_file))

    assert result.success is True
    assert result.steps_completed > 0
```

### Using Fixtures

The `conftest.py` provides reusable fixtures:

```python
def test_with_temp_dir(temp_dir):
    """Test using temporary directory."""
    test_file = temp_dir / "test.txt"
    test_file.write_text("content")
    assert test_file.exists()

def test_with_mock_adapters(mock_adapters):
    """Test using mock adapters."""
    adapter = mock_adapters['mock_ai']
    assert adapter.adapter_type == AdapterType.AI
```

## Test Isolation

### Integration Test Isolation

Integration tests use fixtures for proper setup/teardown:

```python
@pytest.fixture
async def isolated_db(temp_dir):
    """Create isolated test database."""
    db_path = temp_dir / "test.db"
    # Setup
    db = await create_database(db_path)
    yield db
    # Teardown
    await db.close()
    db_path.unlink()

@pytest.mark.integration
async def test_database_operations(isolated_db):
    """Test with isolated database."""
    result = await isolated_db.query("SELECT 1")
    assert result is not None
```

### Parallel Test Execution

Tests are designed to run in parallel:

```bash
# Run tests in parallel (4 workers)
pytest -n 4

# Run tests with specific isolation
pytest --dist loadgroup
```

## Coverage Requirements

### Coverage Thresholds

- **Overall**: ≥85% coverage required
- **Critical paths**: ≥95% coverage recommended
- **New code**: Must not decrease overall coverage

### Coverage Configuration

Coverage is configured in `.coveragerc`:

```ini
[run]
source = src
branch = True

[report]
fail_under = 85
show_missing = True
```

### Checking Coverage

```bash
# Generate coverage report
pytest --cov=src --cov-report=term-missing

# Generate HTML coverage report
pytest --cov=src --cov-report=html
open htmlcov/index.html

# Check if coverage meets threshold
coverage report --fail-under=85
```

## Test Data Factories

Use `TestDataFactory` for generating test data:

```python
def test_with_factory(test_data_factory):
    """Test using data factory."""
    workflow_data = test_data_factory.create_workflow_data(
        name="Custom Workflow",
        steps=[...]
    )

    result_data = test_data_factory.create_adapter_result(
        success=True,
        tokens_used=100
    )
```

## Mocking and Patching

### Mocking External Services

```python
from unittest.mock import Mock, patch

def test_with_mock():
    """Test with mocked external service."""
    with patch('src.cli_multi_rapid.adapters.api_client') as mock_client:
        mock_client.get.return_value = {'status': 'ok'}

        result = call_external_service()

        assert result['status'] == 'ok'
        mock_client.get.assert_called_once()
```

### Async Mocking

```python
from unittest.mock import AsyncMock

@pytest.mark.asyncio
async def test_async_operation():
    """Test async operation with mock."""
    mock_service = AsyncMock()
    mock_service.fetch_data.return_value = {'data': 'test'}

    result = await process_data(mock_service)

    assert result['data'] == 'test'
    mock_service.fetch_data.assert_awaited_once()
```

## Performance Testing

### Performance Monitoring

```python
@pytest.mark.performance
def test_performance(performance_monitor):
    """Test performance targets."""
    performance_monitor.start()

    # Execute operation
    result = expensive_operation()

    duration = performance_monitor.get_duration()
    performance_monitor.record_metric('operation_time', duration)

    # Assert performance targets
    assert duration < 1.0  # Must complete in < 1 second
```

## Contract Testing

### Schema Validation

```python
@pytest.mark.contract
def test_workflow_schema(sample_workflow, workflow_schema, contract_validator):
    """Test workflow adheres to schema."""
    contract_validator.validate_workflow_schema(
        sample_workflow,
        workflow_schema
    )
```

### Adapter Contract Validation

```python
def test_adapter_contract(mock_adapters, contract_validator):
    """Test adapter result contract."""
    adapter = mock_adapters['mock_deterministic']
    result = adapter.execute({'id': '1.001', 'actor': 'mock_deterministic'})

    contract_validator.validate_adapter_result_contract(result)
```

## Continuous Integration

### GitHub Actions Workflows

**`tests.yml`** - Runs on every push:
- Executes full test suite
- Generates coverage reports
- Enforces 85% coverage threshold
- Uploads coverage to Codecov

**`pr-coverage-check.yml`** - Runs on PRs:
- Comments coverage report on PR
- Fails if coverage drops below threshold
- Annotates missing coverage

### Local CI Simulation

```bash
# Run full CI suite locally
make ci

# Or using task
task ci

# Or manually
pytest --cov=src --cov-report=term-missing --cov-report=xml
coverage report --fail-under=85
```

## Troubleshooting

### Common Issues

**Import errors:**
```bash
# Ensure package is installed in editable mode
pip install -e .
```

**Fixture not found:**
```bash
# Check conftest.py is in correct location
# Ensure fixture is properly decorated with @pytest.fixture
```

**Coverage not accurate:**
```bash
# Clear coverage data
coverage erase

# Run tests again
pytest --cov=src
```

### Debugging Tests

```bash
# Run with verbose output
pytest -vv

# Show print statements
pytest -s

# Drop into debugger on failure
pytest --pdb

# Run specific test with debugging
pytest tests/unit/test_something.py::test_function -vv -s --pdb
```

## Best Practices

1. **Test Naming**: Use descriptive names that explain what is being tested
2. **Arrange-Act-Assert**: Structure tests clearly with setup, execution, and verification
3. **One Assertion**: Focus each test on a single behavior (when possible)
4. **Isolation**: Ensure tests don't depend on each other
5. **Speed**: Keep unit tests fast (< 100ms), use marks for slow tests
6. **Coverage**: Aim for 100% coverage of critical paths
7. **Documentation**: Document complex test setups and edge cases

## Resources

- [pytest Documentation](https://docs.pytest.org/)
- [Coverage.py Documentation](https://coverage.readthedocs.io/)
- [CONTRIBUTING.md](../../CONTRIBUTING.md) - General contribution guidelines
