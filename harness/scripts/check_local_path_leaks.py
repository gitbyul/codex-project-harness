#!/usr/bin/env python3
from __future__ import annotations

import os
from pathlib import Path


ROOT = Path(os.environ.get("HARNESS_PROJECT_ROOT", Path(__file__).resolve().parents[2])).resolve()
IGNORED_DIRS = {".git", "__pycache__", ".pytest_cache", ".ruff_cache", ".mypy_cache"}
IGNORED_SUFFIXES = {".pyc", ".pyo"}


def leak_patterns() -> list[str]:
    patterns = [
        "/" + "Users" + "/",
        "/" + "private" + "/",
        "/" + "var" + "/" + "folders",
        "Desktop" + "/" + "project",
    ]
    for name in ("USER", "LOGNAME"):
        value = os.environ.get(name, "").strip()
        if value:
            patterns.append(value)
    home = os.environ.get("HOME", "").strip()
    if home:
        patterns.append(home)
    return sorted(set(patterns))


def candidate_files() -> list[Path]:
    files: list[Path] = []
    for path in ROOT.rglob("*"):
        relative = path.relative_to(ROOT)
        if any(part in IGNORED_DIRS for part in relative.parts):
            continue
        if not path.is_file() or path.suffix in IGNORED_SUFFIXES:
            continue
        files.append(path)
    return sorted(files)


def is_binary(path: Path) -> bool:
    try:
        return b"\0" in path.read_bytes()[:4096]
    except OSError:
        return True


def main() -> int:
    patterns = leak_patterns()
    findings: list[str] = []
    for path in candidate_files():
        if is_binary(path):
            continue
        text = path.read_text(encoding="utf-8", errors="ignore")
        for line_number, line in enumerate(text.splitlines(), start=1):
            if any(pattern and pattern in line for pattern in patterns):
                findings.append(f"{path.relative_to(ROOT)}:{line_number}")

    if findings:
        print("local path leak validation failed:")
        for finding in findings[:50]:
            print(f"- {finding}")
        return 1

    print("local path leak validation passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
