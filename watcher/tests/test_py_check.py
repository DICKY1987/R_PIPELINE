import json
import subprocess
import tempfile
from pathlib import Path

PY = "python"

def run_py_check(file_path):
    proc = subprocess.run([PY, str(Path(__file__).resolve().parents[1] / "py_check.py"), "--file", str(file_path)], capture_output=True, text=True)
    return proc.returncode, proc.stdout.strip(), proc.stderr.strip()

def test_py_check_ok(tmp_path):
    f = tmp_path / "ok.py"
    f.write_text("def f():\n    return 1\n")
    rc, out, err = run_py_check(f)
    assert rc == 0
    j = json.loads(out)
    assert j["status"] == "ok"
    assert j["file"].endswith("ok.py")

def test_py_check_syntax_error(tmp_path):
    f = tmp_path / "bad.py"
    f.write_text("def f()\n    return 1\n")
    rc, out, err = run_py_check(f)
    assert rc != 0
    j = json.loads(out)
    assert j["status"] == "error"
    assert "invalid syntax" in j.get("error", "") or j.get("error")