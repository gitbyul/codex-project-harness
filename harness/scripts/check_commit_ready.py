#!/usr/bin/env python3
from __future__ import annotations

import os
import subprocess
from datetime import UTC, datetime
from fnmatch import fnmatch
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MAIN_BRANCHES = {"main", "master"}


def run_git(args: list[str]) -> str:
    return subprocess.check_output(["git", *args], cwd=ROOT, text=True).strip()


def staged_files() -> list[str]:
    output = run_git(["diff", "--cached", "--name-only"])
    return [line for line in output.splitlines() if line.strip()]


def unstaged_tracked_files() -> list[str]:
    output = run_git(["diff", "--name-only"])
    return [line for line in output.splitlines() if line.strip()]


def untracked_files() -> list[str]:
    output = run_git(["ls-files", "--others", "--exclude-standard"])
    return [line for line in output.splitlines() if line.strip()]


def current_branch() -> str:
    return run_git(["branch", "--show-current"])


def active_plans() -> list[Path]:
    return sorted((ROOT / "docs/exec-plans/active").glob("*.md"))


def staged_completed_plans(files: list[str]) -> list[str]:
    return [
        file
        for file in files
        if file.startswith("docs/exec-plans/completed/") and file.endswith(".md")
    ]


def staged_plan_paths(files: list[str]) -> list[Path]:
    plan_files = [
        file
        for file in files
        if file.startswith("docs/exec-plans/") and file.endswith(".md")
    ]
    return [ROOT / file for file in plan_files if (ROOT / file).is_file()]


def bypass_requested() -> bool:
    return any(
        os.environ.get(name) == "1"
        for name in ("HARNESS_ALLOW_MAIN_COMMIT", "HARNESS_ALLOW_NO_PLAN", "HARNESS_ALLOW_DIRTY_WORKTREE")
    )


def bypass_reason() -> str:
    return os.environ.get("HARNESS_BYPASS_REASON", "").strip()


def record_bypass(reason: str) -> None:
    git_path = Path(run_git(["rev-parse", "--git-dir"]))
    if not git_path.is_absolute():
        git_path = ROOT / git_path
    log_path = git_path / "harness-bypass.log"
    timestamp = datetime.now(UTC).isoformat()
    branch = current_branch() or "DETACHED"
    log_path.open("a", encoding="utf-8").write(f"{timestamp}\t{branch}\t{reason}\n")


def section_lines(body: str, headings: tuple[str, ...]) -> list[str]:
    lines = body.splitlines()
    inside = False
    collected: list[str] = []
    heading_markers = {f"## {heading}" for heading in headings} | {
        f"### {heading}" for heading in headings
    }
    for line in lines:
        if line.startswith("## "):
            if line in heading_markers:
                inside = True
                continue
            if inside:
                break
        if inside:
            collected.append(line.strip())
    return collected


def plan_file_patterns(plan: Path) -> list[str]:
    body = plan.read_text(encoding="utf-8")
    patterns: list[str] = []
    for line in section_lines(body, ("영향 파일", "변경 범위", "Affected Files")):
        if line.startswith("- "):
            patterns.append(line[2:].strip().strip("`"))
    return patterns


def staged_files_outside_plan(files: list[str], plans: list[Path]) -> list[str]:
    patterns: list[str] = []
    for plan in plans:
        patterns.extend(plan_file_patterns(plan))

    if not patterns:
        return files

    outside: list[str] = []
    for file in files:
        if file.startswith("docs/exec-plans/"):
            continue
        if not any(fnmatch(file, pattern) for pattern in patterns):
            outside.append(file)
    return outside


def files_outside_plan(files: list[str], plans: list[Path]) -> list[str]:
    if not plans:
        return []
    patterns: list[str] = []
    for plan in plans:
        patterns.extend(plan_file_patterns(plan))
    if not patterns:
        return []
    return [
        file
        for file in files
        if not file.startswith("docs/exec-plans/")
        and not any(fnmatch(file, pattern) for pattern in patterns)
    ]


def main() -> int:
    errors: list[str] = []

    files = staged_files()
    plans = active_plans()
    if not files:
        errors.append("스테이징된 변경이 없습니다.")

    dirty_files = unstaged_tracked_files()
    extra_files = untracked_files()
    scope_plans = staged_plan_paths(files) or plans
    if (dirty_files or extra_files) and os.environ.get("HARNESS_ALLOW_DIRTY_WORKTREE") != "1":
        errors.append(
            "staged 변경과 검증 대상을 일치시키기 위해 unstaged/untracked 변경을 차단합니다. "
            "모두 스테이징하거나 별도 보관하세요."
        )
        for file in dirty_files[:10]:
            errors.append(f"unstaged: {file}")
        for file in extra_files[:10]:
            errors.append(f"untracked: {file}")
        mixed_work_files = files_outside_plan(dirty_files + extra_files, scope_plans)
        if mixed_work_files:
            errors.append(
                "실행 계획 범위 밖 unstaged/untracked 파일이 있습니다. "
                "다른 에이전트 작업이 같은 worktree에 섞였을 수 있으므로 별도 worktree로 옮기거나 stash로 보관하세요."
            )
            for file in mixed_work_files[:10]:
                errors.append(f"outside plan dirty: {file}")

    branch = current_branch()
    if branch in MAIN_BRANCHES and os.environ.get("HARNESS_ALLOW_MAIN_COMMIT") != "1":
        errors.append(
            "main/master 직접 커밋은 차단됩니다. 작업 브랜치 또는 Git worktree를 사용하세요."
        )

    if (
        not plans
        and not staged_completed_plans(files)
        and os.environ.get("HARNESS_ALLOW_NO_PLAN") != "1"
    ):
        errors.append(
            "활성 실행 계획이 없습니다. docs/exec-plans/active/에 계획을 만들거나 "
            "HARNESS_ALLOW_NO_PLAN=1로 명시적으로 우회하세요."
        )

    if scope_plans:
        missing_patterns = [
            str(plan.relative_to(ROOT)) for plan in scope_plans if not plan_file_patterns(plan)
        ]
        if missing_patterns:
            errors.append(
                "활성 실행 계획에는 '영향 파일' 또는 '변경 범위' 섹션이 필요합니다: "
                + ", ".join(missing_patterns)
            )
        outside = staged_files_outside_plan(files, scope_plans)
        if outside:
            errors.append("실행 계획의 영향 파일 범위를 벗어난 staged 변경이 있습니다.")
            for file in outside[:10]:
                errors.append(f"outside plan: {file}")

    if bypass_requested() and not bypass_reason():
        errors.append("하네스 우회 시 HARNESS_BYPASS_REASON을 반드시 입력해야 합니다.")

    if errors:
        print("commit readiness validation failed:")
        for error in errors:
            print(f"- {error}")
        return 1

    if bypass_requested():
        record_bypass(bypass_reason())

    subprocess.check_call(["python3", "scripts/check_git_hooks.py", "--installed"], cwd=ROOT)
    subprocess.check_call(["./scripts/verify.sh"], cwd=ROOT)
    print("commit readiness validation passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
