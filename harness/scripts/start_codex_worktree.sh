#!/usr/bin/env bash
set -euo pipefail

HARNESS_SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="${HARNESS_PROJECT_ROOT:-$(pwd)}"
cd "$PROJECT_ROOT"
export HARNESS_PROJECT_ROOT="$PROJECT_ROOT"

if [ "$#" -lt 1 ]; then
  echo "usage: ./scripts/start_codex_worktree.sh '<작업 이름>' [branch-name] [worktree-path]"
  exit 2
fi

title="$1"
slug="$(python3 "$HARNESS_SCRIPT_DIR/slugify.py" "$title")"
branch="${2:-task/$slug}"
safe_branch="${branch//\//-}"
target="${3:-../$(basename "$(pwd)")-$safe_branch}"

case "$branch" in
  main|master)
    echo "main/master 브랜치 이름으로 작업 worktree를 만들 수 없습니다."
    exit 1
    ;;
esac

main_branch="$(git branch --show-current)"
if [ "$main_branch" = "main" ] || [ "$main_branch" = "master" ]; then
  if ! git diff --quiet || ! git diff --cached --quiet || [ -n "$(git ls-files --others --exclude-standard)" ]; then
    echo "현재 main/master worktree가 깨끗해야 새 Codex 작업 worktree를 시작합니다."
    echo "진행 중인 변경을 먼저 커밋하거나 별도 worktree에서 이 명령을 실행하세요."
    exit 1
  fi
fi

"$HARNESS_SCRIPT_DIR/create_worktree.sh" "$branch" "$target"

(
  cd "$target"
  HARNESS_PROJECT_ROOT="$PWD" "$HARNESS_SCRIPT_DIR/install_git_hooks.sh"
  HARNESS_PROJECT_ROOT="$PWD" "$HARNESS_SCRIPT_DIR/start_task.sh" "$title" "$branch"
)

echo "codex worktree ready: $target"
echo "branch: $branch"
echo "next: cd $target"
