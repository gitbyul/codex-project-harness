#!/usr/bin/env bash
set -euo pipefail

HARNESS_SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="${HARNESS_PROJECT_ROOT:-$(pwd)}"
cd "$PROJECT_ROOT"
export HARNESS_PROJECT_ROOT="$PROJECT_ROOT"

if [ "$#" -lt 1 ]; then
  echo "usage: ./scripts/finish_goal.sh '<type>(scope): 한국어 설명' [main-branch]"
  exit 2
fi

message="$1"
main_branch="${2:-main}"

python3 "$HARNESS_SCRIPT_DIR/manage_goal.py" assert-finish-goal
goal_file="$(find docs/goals/active -maxdepth 1 -type f -name '*.md' | sort | head -n 1)"
goal_slug="$(basename "$goal_file" .md)"
branch="task/finish-goal-${goal_slug}"
safe_branch="${branch//\//-}"
target="../$(basename "$(pwd)")-$safe_branch"

"$HARNESS_SCRIPT_DIR/start_codex_worktree.sh" "Finish goal ${goal_slug}" "$branch" "$target"

(
  cd "$target"
  HARNESS_PROJECT_ROOT="$PWD" python3 "$HARNESS_SCRIPT_DIR/manage_goal.py" finish-goal
  HARNESS_PROJECT_ROOT="$PWD" "$HARNESS_SCRIPT_DIR/finish_codex_worktree_task.sh" "$message" "" "$main_branch"
)

echo "goal finished: $goal_slug"
