#!/usr/bin/env python3
"""
consumer.py
Lightweight consumer that reads .runs/watch/*.json and emits a summarized report (stdout and .runs/watch/summary.json).
"""
import json
from pathlib import Path
from collections import Counter

def find_json_runs(run_dir: Path):
    if not run_dir.exists():
        return []
    files = sorted(run_dir.glob('*.json'), key=lambda p: p.stat().st_mtime, reverse=True)
    return files

def load_latest(run_dir: Path):
    files = find_json_runs(run_dir)
    if not files:
        return []
    # load the newest
    with files[0].open('r', encoding='utf8') as f:
        return json.load(f)

def summarize(records):
    counters = Counter()
    handlers = Counter()
    for r in records:
        counters[r.get('status','unknown')] += 1
        handlers[r.get('handler','unknown')] += 1
    return {
        'total_records': len(records),
        'by_status': dict(counters),
        'by_handler': dict(handlers)
    }

def main():
    run_dir = Path('.runs/watch')
    records = load_latest(run_dir)
    summary = summarize(records)
    out_path = run_dir / 'summary.json'
    run_dir.mkdir(parents=True, exist_ok=True)
    with out_path.open('w', encoding='utf8') as f:
        json.dump(summary, f, indent=2)
    print(json.dumps(summary, indent=2))

if __name__ == '__main__':
    main()