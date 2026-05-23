#!/usr/bin/env python3
from __future__ import annotations

import os
from pathlib import Path

ROOT = Path(os.environ.get("HARNESS_PROJECT_ROOT", Path(__file__).resolve().parents[1])).resolve()
ACTIVE_DIR = ROOT / "docs/exec-plans/active"
REQUIRED_SECTIONS = [
    ("상태", "Status"),
    ("목표", "Goal"),
    ("단계", "Phase"),
    ("관련 문서", "Related Docs"),
    ("영향 파일", "변경 범위", "Affected Files"),
    ("아티팩트", "Artifacts"),
    ("인수 기준", "Acceptance Criteria"),
    ("구현 계획", "Implementation Plan"),
    ("검증", "Validation"),
    ("결정 기록", "Decision Log"),
    ("위험", "Risks"),
]


def section_present(body: str, section_options: tuple[str, ...]) -> bool:
    markers = []
    for section in section_options:
        markers.extend([f"## {section}", f"### {section}"])
    return any(marker in body for marker in markers)


def main() -> int:
    errors: list[str] = []
    plans = sorted(ACTIVE_DIR.glob("*.md"))

    if not plans:
        print("execution plan validation passed: no active plans")
        return 0

    for plan in plans:
        body = plan.read_text(encoding="utf-8")
        for section_options in REQUIRED_SECTIONS:
            if not section_present(body, section_options):
                errors.append(
                    f"{plan.relative_to(ROOT)} missing section: {' or '.join(section_options)}"
                )
        if "```bash" not in body:
            errors.append(f"{plan.relative_to(ROOT)} should include validation commands in a bash block")
        if "docs/" not in body:
            errors.append(f"{plan.relative_to(ROOT)} should reference related docs")

    if errors:
        print("execution plan validation failed:")
        for error in errors:
            print(f"- {error}")
        return 1

    print("execution plan validation passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
