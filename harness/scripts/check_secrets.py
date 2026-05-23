#!/usr/bin/env python3
from __future__ import annotations

import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MAX_TEXT_BYTES = 1_000_000
SECRET_PATTERNS = [
    ("generic api key", re.compile(r"(?i)(api[_-]?key|secret|token|password)\s*[:=]\s*['\"]?[A-Za-z0-9_./+=-]{16,}")),
    ("github token", re.compile(r"gh[pousr]_[A-Za-z0-9_]{20,}")),
    ("aws access key", re.compile(r"AKIA[0-9A-Z]{16}")),
    ("private key", re.compile(r"-----BEGIN (?:RSA |OPENSSH |EC |DSA )?PRIVATE KEY-----")),
]


def staged_files() -> list[str]:
    output = subprocess.check_output(
        ["git", "diff", "--cached", "--name-only"], cwd=ROOT, text=True
    ).strip()
    return [line for line in output.splitlines() if line.strip()]


def is_binary(path: Path) -> bool:
    data = path.read_bytes()[:4096]
    return b"\0" in data


def check_file(path: Path, errors: list[str]) -> None:
    if not path.is_file() or is_binary(path) or path.stat().st_size > MAX_TEXT_BYTES:
        return
    text = path.read_text(encoding="utf-8", errors="ignore")
    for name, pattern in SECRET_PATTERNS:
        if pattern.search(text):
            errors.append(f"{name} 의심 패턴이 staged 파일에 있습니다: {path.relative_to(ROOT)}")


def main() -> int:
    errors: list[str] = []
    for file in staged_files():
        check_file(ROOT / file, errors)

    if errors:
        print("secret validation failed:")
        for error in errors:
            print(f"- {error}")
        return 1

    print("secret validation passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
