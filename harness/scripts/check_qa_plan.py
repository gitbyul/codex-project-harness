#!/usr/bin/env python3
from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path
from typing import Any

sys.path.insert(0, str(Path(__file__).resolve().parent))
from harness_config import get_path, parse_config  # noqa: E402


ROOT = Path(os.environ.get("HARNESS_PROJECT_ROOT", Path.cwd())).resolve()
REQUIRED_SECTIONS = ("QA 계획", "QA 결과")


def config_bool(value: Any, default: bool) -> bool:
    if value in {"true", "True"}:
        return True
    if value in {"false", "False"}:
        return False
    if isinstance(value, bool):
        return value
    return default


def has_heading(body: str, heading: str) -> bool:
    return f"\n## {heading}\n" in f"\n{body}"


def main() -> int:
    config = parse_config(ROOT / ".codex-harness.yml")
    required = config_bool(get_path(config, "quality.required_plan_sections"), True)
    if not required:
        print("QA plan validation skipped: disabled")
        return 0

    plans = sorted((ROOT / "docs/exec-plans/active").glob("*.md"))
    try:
        staged = subprocess.check_output(
            ["git", "diff", "--cached", "--name-only"],
            cwd=ROOT,
            text=True,
            stderr=subprocess.DEVNULL,
        ).splitlines()
    except subprocess.CalledProcessError:
        staged = []
    for file in staged:
        if file.startswith("docs/exec-plans/completed/") and file.endswith(".md"):
            path = ROOT / file
            if path.is_file():
                plans.append(path)
    errors: list[str] = []
    for plan in plans:
        body = plan.read_text(encoding="utf-8")
        missing = [section for section in REQUIRED_SECTIONS if not has_heading(body, section)]
        if missing:
            errors.append(f"{plan.relative_to(ROOT)} missing sections: {', '.join(missing)}")

    if errors:
        print("QA plan validation failed:")
        for error in errors:
            print(f"- {error}")
        return 1

    print("QA plan validation passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
