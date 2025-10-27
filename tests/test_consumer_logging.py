import json
import logging
from pathlib import Path
import runpy
import os


def test_consumer_logs_json_summary(tmp_path: Path, caplog) -> None:
    # Arrange: create repo-like root with .runs/watch and a single-record JSON
    repo_root = tmp_path
    run_dir = repo_root / ".runs" / "watch"
    run_dir.mkdir(parents=True, exist_ok=True)
    record = {
        "file": "x.py",
        "handler": "python-syntax-check",
        "status": "ok",
        "timestamp": "2025-01-01T00:00:00Z",
        "steps": [{"name": "s", "elapsed_ms": 1, "success": True}],
        "success": True,
        "details": {},
    }
    (run_dir / "latest.json").write_text(json.dumps(record), encoding="utf-8")

    # Load consumer module directly and run main from the temp repo root
    consumer_path = Path(__file__).resolve().parents[1] / "watcher" / "consumer.py"
    mod = runpy.run_path(str(consumer_path))

    # Capture logs from the watcher.consumer logger
    caplog.set_level(logging.INFO, logger="watcher.consumer")
    cwd = os.getcwd()
    try:
        os.chdir(repo_root)
        mod["main"]()
    finally:
        os.chdir(cwd)

    # Assert: summary file written and a JSON log line emitted
    summary_path = run_dir / "summary.json"
    assert summary_path.exists()

    messages = [rec.message for rec in caplog.records if rec.name == "watcher.consumer"]
    assert messages, "Expected a log message from watcher.consumer"
    # Last message should parse as JSON and contain expected keys
    data = json.loads(messages[-1])
    assert data["total_records"] == 1
    assert data["by_status"].get("ok") == 1
    assert data["by_handler"].get("python-syntax-check") == 1
