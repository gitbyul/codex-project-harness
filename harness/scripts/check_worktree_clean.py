#!/usr/bin/env python3
from __future__ import annotations

import argparse
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def worktree_paths() -> dict[str, Path]:
    output = subprocess.check_output(["git", "worktree", "list", "--porcelain"], cwd=ROOT, text=True)
    paths: dict[str, Path] = {}
    current_path: Path | None = None
    for line in output.splitlines():
        if line.startswith("worktree "):
            current_path = Path(line.removeprefix("worktree ")).resolve()
        elif line.startswith("branch ") and current_path:
            branch = line.removeprefix("branch refs/heads/")
            paths[branch] = current_path
    return paths


def branch_path(branch: str) -> Path:
    paths = worktree_paths()
    if branch not in paths:
        return ROOT
    return paths[branch]


def git_output(path: Path, args: list[str]) -> str:
    return subprocess.check_output(["git", *args], cwd=path, text=True).strip()


def dirty_entries(path: Path) -> list[str]:
    entries: list[str] = []
    unstaged = git_output(path, ["diff", "--name-only"])
    staged = git_output(path, ["diff", "--cached", "--name-only"])
    untracked = git_output(path, ["ls-files", "--others", "--exclude-standard"])
    entries.extend(f"unstaged: {line}" for line in unstaged.splitlines() if line.strip())
    entries.extend(f"staged: {line}" for line in staged.splitlines() if line.strip())
    entries.extend(f"untracked: {line}" for line in untracked.splitlines() if line.strip())
    return entries


def main() -> int:
    parser = argparse.ArgumentParser(description="브랜치 worktree clean 상태 검증")
    parser.add_argument("branch")
    args = parser.parse_args()

    path = branch_path(args.branch)
    entries = dirty_entries(path)
    if entries:
        print("worktree clean validation failed:")
        print(f"- branch: {args.branch}")
        print(f"- worktree: {path}")
        for entry in entries[:20]:
            print(f"- {entry}")
        return 1

    print("worktree clean validation passed")
    print(f"- branch: {args.branch}")
    print(f"- worktree: {path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
