#!/usr/bin/env bash
set -euo pipefail

HARNESS_SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="${HARNESS_PROJECT_ROOT:-$(pwd)}"
cd "$PROJECT_ROOT"
export HARNESS_PROJECT_ROOT="$PROJECT_ROOT"

if [ "$#" -lt 1 ]; then
  echo "usage: ./scripts/finish_goal_unit.sh '<type>(scope): 한국어 설명' [plan-path] [main-branch]"
  exit 2
fi

message="$1"
plan="${2:-}"
main_branch="${3:-main}"
branch="$(git branch --show-current)"

python3 "$HARNESS_SCRIPT_DIR/manage_goal.py" assert-finish-unit "$branch"
python3 "$HARNESS_SCRIPT_DIR/manage_goal.py" complete-unit "$branch"
"$HARNESS_SCRIPT_DIR/finish_codex_worktree_task.sh" "$message" "$plan" "$main_branch"

echo "goal unit finished: $branch"
