#!/usr/bin/env python3
from __future__ import annotations

import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RUNS_DIR = ROOT / "artifacts/runs"
PLAN_DIRS = [ROOT / "docs/exec-plans/active", ROOT / "docs/exec-plans/completed"]
REQUIRED_RUN_SECTIONS = [
    "작업 ID",
    "실행 계획",
    "시작 시각",
    "종료 시각",
    "담당 에이전트",
    "변경 파일",
    "실행 명령",
    "검증 결과",
    "아티팩트",
    "남은 이슈",
    "민감 정보 점검",
]
BLOCKED_STAGED_SUFFIXES = {
    ".wav",
    ".mp3",
    ".flac",
    ".ogg",
    ".m4a",
    ".png",
    ".jpg",
    ".jpeg",
    ".gif",
    ".webp",
    ".mp4",
    ".mov",
    ".avi",
    ".onnx",
    ".pt",
    ".pth",
    ".ckpt",
    ".safetensors",
    ".bin",
}


def staged_files() -> list[str]:
    output = subprocess.check_output(
        ["git", "diff", "--cached", "--name-only"], cwd=ROOT, text=True
    ).strip()
    return [line for line in output.splitlines() if line.strip()]


def section_present(body: str, section: str) -> bool:
    return f"## {section}" in body or f"### {section}" in body


def section_lines(body: str, headings: tuple[str, ...]) -> list[str]:
    lines = body.splitlines()
    inside = False
    collected: list[str] = []
    markers = {f"## {heading}" for heading in headings} | {f"### {heading}" for heading in headings}
    for line in lines:
        if line.startswith("## "):
            if line in markers:
                inside = True
                continue
            if inside:
                break
        if inside:
            collected.append(line)
    return collected


def artifact_refs(body: str) -> list[str]:
    refs: list[str] = []
    for line in section_lines(body, ("아티팩트", "Artifacts")):
        if "artifacts/runs/" not in line:
            continue
        parts = line.split("`")
        for index, part in enumerate(parts):
            if index % 2 == 1 and part.startswith("artifacts/runs/"):
                if part.endswith("/run.md"):
                    refs.append(part)
    return refs


def check_run_files(errors: list[str]) -> None:
    if not RUNS_DIR.exists():
        errors.append("artifacts/runs 디렉터리가 없습니다.")
        return

    for run_file in sorted(RUNS_DIR.glob("*/run.md")):
        body = run_file.read_text(encoding="utf-8")
        for section in REQUIRED_RUN_SECTIONS:
            if not section_present(body, section):
                errors.append(f"{run_file.relative_to(ROOT)} missing section: {section}")


def check_plan_artifact_refs(errors: list[str]) -> None:
    for plan_dir in PLAN_DIRS:
        if not plan_dir.exists():
            continue
        for plan in sorted(plan_dir.glob("*.md")):
            body = plan.read_text(encoding="utf-8")
            if "## 아티팩트" not in body and "### 아티팩트" not in body:
                if plan_dir.name == "active":
                    errors.append(f"{plan.relative_to(ROOT)} missing section: 아티팩트")
                continue
            refs = artifact_refs(body)
            if not refs:
                errors.append(f"{plan.relative_to(ROOT)} has 아티팩트 section without run.md ref")
            for ref in refs:
                path = ROOT / ref
                if not path.is_file():
                    errors.append(f"{plan.relative_to(ROOT)} references missing artifact: {ref}")


def check_blocked_staged_files(errors: list[str]) -> None:
    for file in staged_files():
        suffix = Path(file).suffix.lower()
        if suffix in BLOCKED_STAGED_SUFFIXES:
            errors.append(f"민감/대용량 가능성이 있는 파일은 Git에 직접 커밋하지 않습니다: {file}")


def main() -> int:
    errors: list[str] = []
    check_run_files(errors)
    check_plan_artifact_refs(errors)
    check_blocked_staged_files(errors)

    if errors:
        print("artifact validation failed:")
        for error in errors:
            print(f"- {error}")
        return 1

    print("artifact validation passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
