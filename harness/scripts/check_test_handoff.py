#!/usr/bin/env python3
from __future__ import annotations

import os
import argparse
import subprocess
from pathlib import Path

ROOT = Path(os.environ.get("HARNESS_PROJECT_ROOT", Path(__file__).resolve().parents[1])).resolve()


def changed_completed_plans(base: str, branch: str) -> list[Path]:
    output = subprocess.check_output(
        ["git", "diff", "--name-only", f"{base}..{branch}", "--", "docs/exec-plans/completed"],
        cwd=ROOT,
        text=True,
    ).strip()
    return [ROOT / line for line in output.splitlines() if line.endswith(".md")]


def section(body: str, headings: tuple[str, ...]) -> str:
    lines = body.splitlines()
    markers = {f"## {heading}" for heading in headings} | {f"### {heading}" for heading in headings}
    inside = False
    collected: list[str] = []
    for line in lines:
        if line.startswith("## "):
            if line in markers:
                inside = True
                continue
            if inside:
                break
        if inside:
            collected.append(line)
    return "\n".join(collected).strip()


def normalized_owner(value: str) -> str:
    lines = [line.strip("- ").strip() for line in value.splitlines() if line.strip()]
    if not lines:
        return ""
    first = lines[0]
    if ":" in first:
        first = first.split(":", 1)[1]
    return first.strip().lower()


def validate_plan(plan: Path) -> list[str]:
    body = plan.read_text(encoding="utf-8")
    errors: list[str] = []

    implementation_owner = normalized_owner(section(body, ("구현 담당", "Implementation Owner")))
    test_owner = normalized_owner(section(body, ("테스트 담당", "Test Owner")))
    test_command = section(body, ("테스트 명령", "Test Command"))
    test_result = section(body, ("테스트 검증 결과", "Test Result"))

    if not implementation_owner:
        errors.append(f"{plan.relative_to(ROOT)} missing section content: 구현 담당")
    if not test_owner:
        errors.append(f"{plan.relative_to(ROOT)} missing section content: 테스트 담당")
    if implementation_owner and test_owner and implementation_owner == test_owner:
        errors.append(f"{plan.relative_to(ROOT)} 구현 담당과 테스트 담당이 같습니다.")
    if "```bash" not in test_command:
        errors.append(f"{plan.relative_to(ROOT)} 테스트 명령에는 bash 코드 블록이 필요합니다.")
    if "통과" not in test_result:
        errors.append(f"{plan.relative_to(ROOT)} 테스트 검증 결과에 통과 기록이 없습니다.")

    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description="독립 테스트 handoff 검증")
    parser.add_argument("--base", default="main")
    parser.add_argument("--branch", default="HEAD")
    parser.add_argument("--plan", type=Path)
    args = parser.parse_args()

    plans = [args.plan] if args.plan else changed_completed_plans(args.base, args.branch)
    if not plans:
        print("test handoff validation failed:")
        print("- 병합 범위에 completed 실행 계획이 없습니다.")
        return 1

    errors: list[str] = []
    for plan in plans:
        if not plan.is_absolute():
            plan = ROOT / plan
        if not plan.is_file():
            errors.append(f"실행 계획 파일이 없습니다: {plan}")
            continue
        errors.extend(validate_plan(plan))

    if errors:
        print("test handoff validation failed:")
        for error in errors:
            print(f"- {error}")
        return 1

    print("test handoff validation passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
