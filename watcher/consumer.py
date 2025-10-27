#!/usr/bin/env python3
"""
consumer.py
Lightweight consumer that reads .runs/watch/*.json and emits a summarized report
to structured logs (stdout) and writes .runs/watch/summary.json.
"""

import json
from pathlib import Path
from collections import Counter
from typing import Any, List
import logging
import sys


def find_json_runs(run_dir: Path) -> List[Path]:
    if not run_dir.exists():
        return []
    files = sorted(
        run_dir.glob("*.json"), key=lambda p: p.stat().st_mtime, reverse=True
    )
    return files


def load_latest(run_dir: Path) -> List[dict[str, Any]]:
    files = find_json_runs(run_dir)
    if not files:
        return []
    # load the newest
    with files[0].open("r", encoding="utf8") as f:
        obj: Any = json.load(f)
        if isinstance(obj, list):
            return obj
        # Normalize a single-record object to a list of one
        return [obj]


def summarize(records: List[dict[str, Any]]) -> dict[str, Any]:
    counters = Counter()
    handlers = Counter()
    for r in records:
        counters[r.get("status", "unknown")] += 1
        handlers[r.get("handler", "unknown")] += 1
    return {
        "total_records": len(records),
        "by_status": dict(counters),
        "by_handler": dict(handlers),
    }


def _get_logger() -> logging.Logger:
    logger = logging.getLogger("watcher.consumer")
    if not logger.handlers:
        handler = logging.StreamHandler(stream=sys.stdout)
        handler.setFormatter(logging.Formatter("%(message)s"))
        logger.addHandler(handler)
    logger.setLevel(logging.INFO)
    return logger


def emit_summary(summary: dict[str, Any]) -> None:
    """Emit the summary as a structured JSON log line to stdout."""
    logger = _get_logger()
    logger.info(json.dumps(summary, separators=(",", ":")))


def main():
    run_dir = Path(".runs/watch")
    records = load_latest(run_dir)
    summary = summarize(records)
    out_path = run_dir / "summary.json"
    run_dir.mkdir(parents=True, exist_ok=True)
    with out_path.open("w", encoding="utf8") as f:
        json.dump(summary, f, indent=2)
    emit_summary(summary)


if __name__ == "__main__":
    main()
