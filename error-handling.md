# Error Handling Guide

This guide explains the standardized error handling system used in this project.

## Philosophy

We use a system of standardized error codes and custom exceptions to make errors predictable, consistent, and easy to debug. When an error occurs, it should be clear what went wrong and how to resolve it.

## Error Codes

All error codes are defined in `src/cli_multi_rapid/errors/error_codes.py`. Each error has a unique code (e.g., `E1001`) and a description.

A full list of error codes and their meanings can be found in the [Error Code Reference](../reference/error-codes.md).

## Custom Exceptions

Custom exception classes are defined in `src/cli_multi_rapid/errors/exceptions.py`. These exceptions should be used throughout the application instead of generic exceptions like `Exception` or `ValueError`.

### Raising an Exception

To raise a standardized error, import the appropriate exception class and raise it with a details message:

```python
from src.cli_multi_rapid.errors.exceptions import FileNotFoundError
import os

def read_my_file(path):
    if not os.path.exists(path):
        raise FileNotFoundError(f"The file at '{path}' could not be found.")
    # ...
```

When this exception is raised, it will automatically be formatted with its corresponding error code and description, along with the specific details you provide.

### Creating a New Exception

If you encounter a new type of error that doesn't fit any of the existing exception classes, you can create a new one:

1.  **Add an Error Code:** Add a new error code to the `ErrorCode` enum in `src/cli_multi_rapid/errors/error_codes.py`.
2.  **Create an Exception Class:** Create a new exception class in `src/cli_multi_rapid/errors/exceptions.py` that inherits from `CLIOrchestratorException` and uses your new error code.
3.  **Document the Error:** Add the new error code, its description, and resolution steps to `docs/reference/error-codes.md`.
