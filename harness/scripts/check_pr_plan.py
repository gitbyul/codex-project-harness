#!/usr/bin/env python3
from __future__ import annotations

import argparse
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
COMPLETED_PREFIX = "docs/exec-plans/completed/"
ACTIVE_PREFIX = "docs/exec-plans/active/"


def changed_files(base: str, branch: str) -> list[str]:
    output = subprocess.check_output(
        ["git", "diff", "--name-only", f"{base}..{branch}"], cwd=ROOT, text=True
    ).strip()
    return [line for line in output.splitlines() if line.strip()]


def main() -> int:
    parser = argparse.ArgumentParser(description="PR 실행 계획 문서 검증")
    parser.add_argument("--base", default="origin/main")
    parser.add_argument("--branch", default="HEAD")
    args = parser.parse_args()

    files = changed_files(args.base, args.branch)
    completed_plans = [
        file for file in files if file.startswith(COMPLETED_PREFIX) and file.endswith(".md")
    ]
    active_plans = [file for file in files if file.startswith(ACTIVE_PREFIX) and file.endswith(".md")]

    errors: list[str] = []
    if not completed_plans:
        errors.append(
            "PR에는 완료된 실행 계획 문서가 포함되어야 합니다: "
            "docs/exec-plans/completed/*.md"
        )

    for plan in completed_plans:
        path = ROOT / plan
        if not path.is_file():
            errors.append(f"완료 실행 계획 파일이 존재하지 않습니다: {plan}")

    if active_plans:
        errors.append(
            "PR에는 active 실행 계획을 남기지 않습니다. 완료 후 completed로 이동하세요: "
            + ", ".join(active_plans)
        )

    if errors:
        print("PR plan validation failed:")
        for error in errors:
            print(f"- {error}")
        return 1

    print("PR plan validation passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
