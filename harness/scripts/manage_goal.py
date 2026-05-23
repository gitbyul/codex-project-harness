#!/usr/bin/env python3
from __future__ import annotations

import re
import subprocess
import sys
from datetime import UTC, datetime
from pathlib import Path


ROOT = Path.cwd().resolve()
ACTIVE_DIR = ROOT / "docs/goals/active"
COMPLETED_DIR = ROOT / "docs/goals/completed"


def run_git(args: list[str], cwd: Path = ROOT) -> str:
    return subprocess.check_output(["git", *args], cwd=cwd, text=True).strip()


def git_common_dir() -> Path:
    path = Path(run_git(["rev-parse", "--git-common-dir"]))
    if not path.is_absolute():
        path = ROOT / path
    return path.resolve()


def state_file() -> Path:
    return git_common_dir() / "codex-harness" / "active-goal"


def slugify(text: str) -> str:
    value = re.sub(r"[^0-9A-Za-z가-힣._-]+", "-", text.strip().lower())
    value = re.sub(r"-+", "-", value).strip("-._")
    return value or "goal"


def current_branch() -> str:
    return run_git(["branch", "--show-current"])


def is_clean(path: Path = ROOT) -> bool:
    return (
        subprocess.run(["git", "diff", "--quiet"], cwd=path).returncode == 0
        and subprocess.run(["git", "diff", "--cached", "--quiet"], cwd=path).returncode == 0
        and not run_git(["ls-files", "--others", "--exclude-standard"], cwd=path)
    )


def active_goals() -> list[Path]:
    return sorted(ACTIVE_DIR.glob("*.md"))


def active_plans() -> list[Path]:
    return sorted((ROOT / "docs/exec-plans/active").glob("*.md"))


def branch_exists(branch: str) -> bool:
    return subprocess.run(
        ["git", "show-ref", "--verify", "--quiet", f"refs/heads/{branch}"],
        cwd=ROOT,
    ).returncode == 0


def branch_worktree(branch: str) -> str:
    output = run_git(["worktree", "list", "--porcelain"])
    path = ""
    for line in output.splitlines():
        if line.startswith("worktree "):
            path = line.removeprefix("worktree ")
        elif line == f"branch refs/heads/{branch}" and path:
            return path
    return ""


def read_state() -> tuple[str, str] | None:
    path = state_file()
    if not path.is_file():
        return None
    lines = path.read_text(encoding="utf-8").splitlines()
    if len(lines) < 2:
        return None
    return lines[0], lines[1]


def write_state(title: str, slug: str) -> None:
    path = state_file()
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(f"{title}\n{slug}\n", encoding="utf-8")


def clear_state() -> None:
    state_file().unlink(missing_ok=True)


def goal_from_state() -> Path:
    state = read_state()
    if not state:
        raise SystemExit("활성 goal 상태를 찾지 못했습니다. 먼저 start_goal.sh를 실행하세요.")
    _, slug = state
    return ACTIVE_DIR / f"{datetime.now(UTC).strftime('%Y%m%d')}-{slug}.md"


def single_active_goal_or_state() -> Path:
    goals = active_goals()
    if len(goals) == 1:
        return goals[0]
    if len(goals) > 1:
        raise SystemExit("활성 goal이 2개 이상입니다. 하나만 남긴 뒤 다시 실행하세요.")
    return goal_from_state()


def ensure_goal_file(path: Path) -> Path:
    if path.is_file():
        return path
    state = read_state()
    if not state:
        raise SystemExit("생성할 goal 상태를 찾지 못했습니다.")
    title, _ = state
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        f"# {title}\n\n"
        "## 상태\n\n진행 중\n\n"
        "## 목표\n\n- \n\n"
        "## 작업 단위\n\n"
        "<!-- goal-units:start -->\n"
        "<!-- goal-units:end -->\n\n"
        "## 완료 조건\n\n"
        "- 모든 작업 단위가 main에 병합되었다.\n"
        "- 작업 브랜치와 작업 worktree가 정리되었다.\n\n"
        "## 결정 기록\n\n- \n\n"
        "## 위험\n\n- \n",
        encoding="utf-8",
    )
    return path


def unit_line(branch: str, title: str, checked: bool = False) -> str:
    mark = "x" if checked else " "
    return f"- [{mark}] `{branch}` - {title}"


def update_units(path: Path, updater) -> None:
    body = path.read_text(encoding="utf-8")
    start = "<!-- goal-units:start -->"
    end = "<!-- goal-units:end -->"
    if start not in body or end not in body:
        raise SystemExit(f"goal 문서에 작업 단위 marker가 없습니다: {path}")
    before, rest = body.split(start, 1)
    current, after = rest.split(end, 1)
    lines = [line for line in current.splitlines() if line.strip()]
    new_lines = updater(lines)
    body = before + start + "\n" + "\n".join(new_lines).rstrip() + "\n" + end + after
    path.write_text(body, encoding="utf-8")


def register_unit(title: str, branch: str) -> None:
    path = ensure_goal_file(single_active_goal_or_state())

    def updater(lines: list[str]) -> list[str]:
        if any(f"`{branch}`" in line for line in lines):
            raise SystemExit(f"이미 등록된 goal unit branch입니다: {branch}")
        return [*lines, unit_line(branch, title)]

    update_units(path, updater)
    clear_state()
    link_active_plan(path, title, branch)
    print(f"registered goal unit: {branch}")


def complete_unit(branch: str) -> None:
    path = single_active_goal_or_state()
    if not path.is_file():
        raise SystemExit("활성 goal 문서를 찾지 못했습니다.")

    def updater(lines: list[str]) -> list[str]:
        found = False
        updated: list[str] = []
        for line in lines:
            if f"`{branch}`" in line:
                found = True
                updated.append(line.replace("- [ ]", "- [x]", 1))
            else:
                updated.append(line)
        if not found:
            raise SystemExit(f"goal 문서에서 현재 branch unit을 찾지 못했습니다: {branch}")
        return updated

    update_units(path, updater)
    print(f"completed goal unit: {branch}")


def unchecked_units(path: Path) -> list[str]:
    body = path.read_text(encoding="utf-8")
    return [line for line in body.splitlines() if line.startswith("- [ ]")]


def link_active_plan(goal_path: Path, title: str, branch: str) -> None:
    plans = active_plans()
    if len(plans) != 1:
        return
    plan = plans[0]
    body = plan.read_text(encoding="utf-8")
    if "\n## Goal\n" in body:
        return
    insert = (
        "## Goal\n\n"
        f"- `{goal_path}`\n\n"
        "## Unit\n\n"
        f"- `{branch}` - {title}\n\n"
    )
    marker = "\n## 관련 문서\n"
    if marker in body:
        body = body.replace(marker, "\n" + insert + "## 관련 문서\n", 1)
    else:
        body = body.rstrip() + "\n\n" + insert
    plan.write_text(body, encoding="utf-8")


def command_start_goal(title: str) -> None:
    if active_goals():
        raise SystemExit("이미 활성 goal 문서가 있습니다.")
    if read_state():
        raise SystemExit("이미 시작된 goal 상태가 있습니다.")
    write_state(title, slugify(title))
    print(f"started goal: {title}")


def command_assert_start_unit(title: str, branch: str, target: str) -> None:
    del title
    single_active_goal_or_state()
    if active_plans():
        raise SystemExit("활성 실행 계획이 남아 있어 새 goal unit을 시작할 수 없습니다.")
    if current_branch() not in {"main", "master"}:
        raise SystemExit("goal unit은 main/master worktree에서만 시작하세요.")
    if not is_clean():
        raise SystemExit("main/master worktree가 깨끗해야 새 goal unit을 시작할 수 있습니다.")
    if branch in {"main", "master"}:
        raise SystemExit("goal unit branch는 main/master가 될 수 없습니다.")
    if branch_exists(branch):
        raise SystemExit(f"이미 존재하는 branch로 goal unit을 시작할 수 없습니다: {branch}")
    if branch_worktree(branch):
        raise SystemExit(f"이미 해당 branch worktree가 있습니다: {branch}")
    if Path(target).exists():
        raise SystemExit(f"이미 worktree 경로가 존재합니다: {target}")


def command_assert_finish_unit(branch: str) -> None:
    if branch in {"main", "master"}:
        raise SystemExit("goal unit 완료는 작업 branch/worktree에서 실행해야 합니다.")
    path = single_active_goal_or_state()
    if not path.is_file() or f"`{branch}`" not in path.read_text(encoding="utf-8"):
        raise SystemExit(f"goal 문서에 현재 unit branch가 없습니다: {branch}")


def command_assert_finish_goal() -> None:
    goals = active_goals()
    if len(goals) != 1:
        raise SystemExit("완료할 활성 goal 문서를 하나로 특정할 수 없습니다.")
    if active_plans():
        raise SystemExit("활성 실행 계획이 남아 있어 goal을 완료할 수 없습니다.")
    pending = unchecked_units(goals[0])
    if pending:
        raise SystemExit("미완료 goal unit이 남아 있습니다:\n" + "\n".join(pending))
    if current_branch() not in {"main", "master"}:
        raise SystemExit("goal 완료는 main/master worktree에서 시작하세요.")
    if not is_clean():
        raise SystemExit("main/master worktree가 깨끗해야 goal 완료 unit을 시작할 수 있습니다.")


def command_finish_goal() -> None:
    goals = active_goals()
    if len(goals) != 1:
        raise SystemExit("완료할 활성 goal 문서를 하나로 특정할 수 없습니다.")
    goal = goals[0]
    pending = unchecked_units(goal)
    if pending:
        raise SystemExit("미완료 goal unit이 남아 있습니다:\n" + "\n".join(pending))
    COMPLETED_DIR.mkdir(parents=True, exist_ok=True)
    body = goal.read_text(encoding="utf-8").replace("진행 중", "완료", 1)
    target = COMPLETED_DIR / goal.name
    target.write_text(body, encoding="utf-8")
    goal.unlink()
    clear_state()
    print(f"completed goal: {target}")


def main() -> int:
    if len(sys.argv) < 2:
        print("usage: manage_goal.py <command> ...")
        return 2
    command = sys.argv[1]
    if command == "start-goal" and len(sys.argv) == 3:
        command_start_goal(sys.argv[2])
    elif command == "assert-start-unit" and len(sys.argv) == 5:
        command_assert_start_unit(sys.argv[2], sys.argv[3], sys.argv[4])
    elif command == "register-unit" and len(sys.argv) == 4:
        register_unit(sys.argv[2], sys.argv[3])
    elif command == "assert-finish-unit" and len(sys.argv) == 3:
        command_assert_finish_unit(sys.argv[2])
    elif command == "complete-unit" and len(sys.argv) == 3:
        complete_unit(sys.argv[2])
    elif command == "assert-finish-goal":
        command_assert_finish_goal()
    elif command == "finish-goal":
        command_finish_goal()
    else:
        print(f"unknown or invalid goal command: {command}")
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
