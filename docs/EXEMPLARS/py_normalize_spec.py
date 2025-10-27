from __future__ import annotations
from typing import Dict, Any


def normalize_spec(spec: Dict[str, Any]) -> Dict[str, Any]:
    """Normalize a user spec.

    Args:
        spec: Raw input mapping.
    Returns:
        Normalized mapping with 'id' and 'name'.
    Raises:
        ValueError: If 'id' is missing or empty.
    """
    if "id" not in spec or not spec["id"]:
        raise ValueError("id required")
    name = str(spec.get("name") or "").strip()
    return {"id": str(spec["id"]).strip(), "name": name or "UNKNOWN"}


# pytest
def test_normalize_spec_success() -> None:
    assert normalize_spec({"id": "42", "name": "  Ada "}) == {
        "id": "42",
        "name": "Ada",
    }


def test_normalize_spec_missing_id_raises() -> None:
    import pytest

    with pytest.raises(ValueError):
        normalize_spec({"name": "Ada"})

