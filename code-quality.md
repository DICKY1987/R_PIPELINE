# Code Quality Guide

This guide outlines the tools and practices we use to maintain high code quality.

## Dead Code Detection with Vulture

We use `vulture` to identify and remove dead (unreachable) code.

### Running Vulture

To check for dead code, run the following command from the root of the repository:

```bash
vulture . --min-confidence 80
```

This will scan the entire project and report any code that it considers unused with at least 80% confidence.

### Handling False Positives

Sometimes, `vulture` may flag code that is intentionally unused (e.g., for future features or in configuration files). To prevent this, add the name of the variable, function, or class to the `.vulture_whitelist.py` file in the root of the repository.

## Documentation Standards

### Documentation Coverage

We aim for high documentation coverage to ensure our codebase is easy to understand and maintain. You can check the current documentation coverage by running:

```bash
python scripts/check_doc_coverage.py
```

This script will report the percentage of modules, classes, and functions that have docstrings.

### Documentation Freshness

Documentation should always be kept up-to-date with the code it describes. Our CI pipeline includes a check to ensure that documentation is not "stale." You can run this check locally:

```bash
python scripts/check_doc_freshness.py
```

If you modify a source file, be sure to update its corresponding documentation to ensure this check passes.
