import json
from pathlib import Path
from typing import Any
import runpy


def test_consumer_handles_single_record(tmp_path: Path) -> None:
    # Arrange: create a run directory with a single-record JSON file
    run_dir = tmp_path / "watch"
    run_dir.mkdir(parents=True, exist_ok=True)
    single_record = {
        "file": "some/path.py",
        "handler": "python-syntax-check",
        "status": "ok",
        "timestamp": "2025-01-01T00:00:00Z",
        "steps": [{"name": "step", "elapsed_ms": 1, "success": True}],
        "success": True,
        "details": {},
    }
    sample = run_dir / "sample.json"
    sample.write_text(json.dumps(single_record), encoding="utf-8")

    # Act: import the consumer and process the latest file
    # Load consumer module directly from file to avoid import path issues
    repo_root = Path(__file__).resolve().parents[1]
    consumer_path = repo_root / "watcher" / "consumer.py"
    mod = runpy.run_path(str(consumer_path))
    consumer: Any = type("_Mod", (), mod)  # lightweight namespace wrapper
    records = consumer.load_latest(run_dir)
    summary = consumer.summarize(records)

    # Assert: one record summarized with correct status/handler tallies
    assert summary["total_records"] == 1
    assert summary["by_status"].get("ok") == 1
    assert summary["by_handler"].get("python-syntax-check") == 1
