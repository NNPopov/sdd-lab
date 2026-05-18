#!/usr/bin/env python3
# STABLE: Architecture check runner — executes all quality and architecture gates sequentially.
"""
Usage:
    python scripts/check_arch.py

Runs (in order):
  1. ruff format  — formatting check (read-only)
  2. ruff check   — lint
  3. mypy         — type check
  4. lint-imports — import contract validation (.importlinter)
  5. pytest       — architecture tests (tests/architecture/)

Exit code 0 if all pass, 1 if any fail.
All steps always run so you get a complete picture of violations.
"""
from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "src"
PYTHON = sys.executable
SEP = "=" * 64


def _run(name: str, cmd: list[str], cwd: Path | None = None, extra_env: dict[str, str] | None = None) -> bool:
    print(f"\n{SEP}")
    print(f"  {name}")
    print(SEP)
    env = {**os.environ, **(extra_env or {})}
    result = subprocess.run(cmd, cwd=cwd or ROOT, env=env)
    ok = result.returncode == 0
    print(f"\n{'PASSED' if ok else 'FAILED'}: {name}")
    return ok


def main() -> None:
    steps: list[tuple[str, list[str], Path | None, dict[str, str] | None]] = [
        (
            "Ruff Format (check only)",
            [PYTHON, "-m", "ruff", "format", "src/app", "--check"],
            None,
            None,
        ),
        (
            "Ruff Lint",
            [PYTHON, "-m", "ruff", "check", "src/app"],
            None,
            None,
        ),
        (
            "Mypy (type check)",
            [PYTHON, "-m", "mypy", "src/app"],
            None,
            None,
        ),
        (
            # lint-imports must run from src/ so that 'app' is on sys.path.
            # Config path is relative to the invocation directory.
            "Import Linter (layer contracts)",
            ["lint-imports", "--config", "../.importlinter"],
            SRC,
            None,
        ),
        (
            "Architecture Tests (pytest)",
            [
                PYTHON,
                "-m",
                "pytest",
                "tests/architecture/",
                "-v",
                "--tb=short",
                "--no-header",
            ],
            None,
            None,
        ),
    ]

    results: list[tuple[str, bool]] = []
    for name, cmd, cwd, extra_env in steps:
        passed = _run(name, cmd, cwd, extra_env)
        results.append((name, passed))

    print(f"\n{SEP}")
    print("  SUMMARY")
    print(SEP)

    for name, ok in results:
        mark = "OK  " if ok else "FAIL"
        print(f"  [{mark}] {name}")

    failed = [name for name, ok in results if not ok]
    if failed:
        print(f"\n{len(failed)} check(s) failed. Fix the issues listed above.")
        sys.exit(1)
    else:
        print("\nAll architecture checks passed.")


if __name__ == "__main__":
    main()
