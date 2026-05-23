#!/usr/bin/env python3
from __future__ import annotations

import os
import argparse
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(os.environ.get("HARNESS_PROJECT_ROOT", Path(__file__).resolve().parents[1])).resolve()


def commit_messages(base: str, head: str) -> list[str]:
    output = subprocess.check_output(
        ["git", "log", "--format=%B%x00", f"{base}..{head}"], cwd=ROOT, text=True
    )
    return [message.strip() for message in output.split("\0") if message.strip()]


def main() -> int:
    parser = argparse.ArgumentParser(description="커밋 범위 메시지 검증")
    parser.add_argument("--base", default="origin/main")
    parser.add_argument("--head", default="HEAD")
    args = parser.parse_args()

    messages = commit_messages(args.base, args.head)
    if not messages:
        print("commit range validation passed: no commits")
        return 0

    for message in messages:
        with tempfile.NamedTemporaryFile("w", encoding="utf-8", delete=False) as file:
            file.write(message)
            path = Path(file.name)
        try:
            subprocess.check_call(["python3", "scripts/check_commit_message.py", str(path)], cwd=ROOT)
        finally:
            path.unlink(missing_ok=True)

    print("commit range validation passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
