#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

if [ "$#" -lt 1 ]; then
  echo "usage: ./scripts/finish_codex_worktree_task.sh '<type>(scope): 한국어 설명' [plan-path] [main-branch]"
  exit 2
fi

message="$1"
plan="${2:-}"
main_branch="${3:-main}"
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

./scripts/install_git_hooks.sh

if [ -z "$plan" ]; then
  mapfile -t active_plans < <(find docs/exec-plans/active -maxdepth 1 -type f -name '*.md' | sort)
  if [ "${#active_plans[@]}" -ne 1 ]; then
    echo "완료할 활성 실행 계획을 하나로 특정할 수 없습니다."
    echo "usage: ./scripts/finish_codex_worktree_task.sh '<type>(scope): 한국어 설명' docs/exec-plans/active/<plan>.md"
    printf 'active plan: %s\n' "${active_plans[@]}"
    exit 1
  fi
  plan="${active_plans[0]}"
fi

if [ -n "$plan" ]; then
  ./scripts/finish_task.sh "$plan"
else
  ./scripts/finish_task.sh
fi

git add -A
./scripts/harness_commit.sh "$message"
./scripts/harness_merge.sh "$branch" "$main_branch"

echo "finished, committed, and merged: $branch -> $main_branch"
