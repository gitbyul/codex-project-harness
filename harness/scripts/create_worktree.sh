#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${HARNESS_PROJECT_ROOT:-$(pwd)}"
cd "$PROJECT_ROOT"

if [ "$#" -lt 1 ]; then
  echo "usage: ./scripts/create_worktree.sh <branch-name> [worktree-path]"
  exit 2
fi

branch="$1"
safe_branch="${branch//\//-}"
target="${2:-../$(basename "$(pwd)")-$safe_branch}"

case "$branch" in
  main|master)
    echo "main/master 브랜치 이름으로 작업 worktree를 만들 수 없습니다."
    exit 1
    ;;
esac

if git show-ref --verify --quiet "refs/heads/$branch"; then
  git worktree add "$target" "$branch"
else
  git worktree add -b "$branch" "$target"
fi

echo "created worktree: $target"
