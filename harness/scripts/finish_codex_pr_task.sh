#!/usr/bin/env bash
set -euo pipefail

HARNESS_SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="${HARNESS_PROJECT_ROOT:-$(pwd)}"
cd "$PROJECT_ROOT"
export HARNESS_PROJECT_ROOT="$PROJECT_ROOT"

if [ "$#" -lt 1 ]; then
  echo "usage: ./scripts/finish_codex_pr_task.sh '<type>(scope): 한국어 설명' [plan-path] [base-branch] [remote]"
  exit 2
fi

message="$1"
plan="${2:-}"
base="${3:-main}"
remote="${4:-origin}"
branch="$(git branch --show-current)"

if [ -z "$branch" ]; then
  echo "현재 브랜치를 확인할 수 없습니다."
  exit 1
fi

case "$branch" in
  main|master)
    echo "작업 브랜치 또는 작업 worktree에서 실행해야 합니다."
    exit 1
    ;;
esac

"$HARNESS_SCRIPT_DIR/install_git_hooks.sh"

if [ -n "$plan" ]; then
  "$HARNESS_SCRIPT_DIR/finish_task.sh" "$plan"
else
  "$HARNESS_SCRIPT_DIR/finish_task.sh"
fi

"$HARNESS_SCRIPT_DIR/harness_publish.sh" "$message" --pr --base "$base" --remote "$remote"

echo "finished, committed, pushed, and opened PR: $branch -> $base"
