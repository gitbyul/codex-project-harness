#!/usr/bin/env python3
from __future__ import annotations

import argparse
from datetime import UTC, datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def artifact_refs(plan: Path) -> list[Path]:
    refs: list[Path] = []
    for line in plan.read_text(encoding="utf-8").splitlines():
        if "artifacts/runs/" not in line:
            continue
        parts = line.split("`")
        for index, part in enumerate(parts):
            if index % 2 == 1 and part.endswith("/run.md"):
                refs.append(ROOT / part)
    return refs


def replace_section(body: str, heading: str, content: str) -> str:
    lines = body.splitlines()
    output: list[str] = []
    index = 0
    marker = f"## {heading}"
    while index < len(lines):
        line = lines[index]
        output.append(line)
        if line == marker:
            index += 1
            while index < len(lines) and not lines[index].startswith("## "):
                index += 1
            output.append("")
            output.extend(content.splitlines())
            continue
        index += 1
    return "\n".join(output).rstrip() + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description="run.md 실행 결과 갱신")
    parser.add_argument("--plan", required=True, type=Path)
    parser.add_argument("--result", required=True)
    parser.add_argument("--ended-now", action="store_true")
    args = parser.parse_args()

    plan = args.plan
    if not plan.is_absolute():
        plan = ROOT / plan

    refs = artifact_refs(plan)
    if not refs:
        print("연결된 run.md가 없습니다.")
        return 1

    ended_at = datetime.now(UTC).strftime("%Y-%m-%dT%H:%M:%SZ")
    for ref in refs:
        body = ref.read_text(encoding="utf-8")
        if args.ended_now:
            body = replace_section(body, "종료 시각", ended_at)
        body = replace_section(body, "검증 결과", f"- {args.result}")
        ref.write_text(body, encoding="utf-8")
        print(f"updated {ref.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
