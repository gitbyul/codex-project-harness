#!/usr/bin/env python3
from __future__ import annotations

import os
import argparse
import subprocess
from pathlib import Path

ROOT = Path(os.environ.get("HARNESS_PROJECT_ROOT", Path(__file__).resolve().parents[1])).resolve()
HOOKS = ("pre-commit", "commit-msg")


def git_dir() -> Path:
    output = subprocess.check_output(["git", "rev-parse", "--git-dir"], cwd=ROOT, text=True).strip()
    path = Path(output)
    if not path.is_absolute():
        path = ROOT / path
    return path


def same_content(left: Path, right: Path) -> bool:
    return left.read_bytes() == right.read_bytes()


def check_templates(errors: list[str]) -> None:
    for hook in HOOKS:
        path = ROOT / "githooks" / hook
        if not path.is_file():
            errors.append(f"hook 템플릿이 없습니다: githooks/{hook}")
        elif not path.stat().st_mode & 0o111:
            errors.append(f"hook 템플릿에 실행 권한이 없습니다: githooks/{hook}")


def core_hooks_path() -> str:
    try:
        return subprocess.check_output(
            ["git", "config", "--get", "core.hooksPath"], cwd=ROOT, text=True
        ).strip()
    except subprocess.CalledProcessError:
        return ""


def check_installed(errors: list[str]) -> None:
    configured = core_hooks_path()
    if configured == "githooks":
        return

    hooks_dir = git_dir() / "hooks"
    for hook in HOOKS:
        template = ROOT / "githooks" / hook
        installed = hooks_dir / hook
        if not installed.is_file():
            errors.append(f"Git hook이 설치되지 않았습니다: {installed}")
            continue
        if not installed.stat().st_mode & 0o111:
            errors.append(f"Git hook에 실행 권한이 없습니다: {installed}")
        if template.is_file() and not same_content(template, installed):
            errors.append(f"설치된 Git hook이 템플릿과 다릅니다: {hook}")


def main() -> int:
    parser = argparse.ArgumentParser(description="Git hook 하네스 검증")
    parser.add_argument("--installed", action="store_true", help="로컬 .git/hooks 설치 상태까지 검사")
    args = parser.parse_args()

    errors: list[str] = []
    check_templates(errors)
    if args.installed:
        check_installed(errors)

    if errors:
        print("git hook validation failed:")
        for error in errors:
            print(f"- {error}")
        return 1

    print("git hook validation passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
