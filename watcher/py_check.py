#!/usr/bin/env python3
"""
py_check.py
Simple Python syntax+smoke-check helper used by watcher/build.ps1.

Usage:
  python py_check.py --file path/to/file.py
Outputs a single JSON object to stdout:
  { "file": "...", "status": "ok"|"error", "error": "..." }
"""
import argparse
import json
import py_compile
from pathlib import Path
import sys

def check_file(path: Path):
    try:
        py_compile.compile(str(path), doraise=True)
        return {"file": str(path), "status": "ok"}
    except py_compile.PyCompileError as e:
        return {"file": str(path), "status": "error", "error": str(e)}
    except Exception as e:
        return {"file": str(path), "status": "error", "error": str(e)}

def main():
    p = argparse.ArgumentParser()
    p.add_argument("--file", required=True)
    args = p.parse_args()
    path = Path(args.file)
    if not path.exists():
        print(json.dumps({"file": str(path), "status": "error", "error": "not_found"}))
        sys.exit(2)
    result = check_file(path)
    print(json.dumps(result))
    if result["status"] != "ok":
        sys.exit(1)

if __name__ == "__main__":
    main()