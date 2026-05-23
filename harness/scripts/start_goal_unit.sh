#!/usr/bin/env bash
set -euo pipefail

HARNESS_SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="${HARNESS_PROJECT_ROOT:-$(pwd)}"
cd "$PROJECT_ROOT"
export HARNESS_PROJECT_ROOT="$PROJECT_ROOT"

if [ "$#" -lt 1 ]; then
  echo "usage: ./scripts/start_goal_unit.sh '<작은 작업 이름>' [branch-name] [worktree-path]"
  exit 2
fi

title="$1"
slug="$(python3 "$HARNESS_SCRIPT_DIR/slugify.py" "$title")"
branch="${2:-task/$slug}"
safe_branch="${branch//\//-}"
target="${3:-../$(basename "$(pwd)")-$safe_branch}"

python3 "$HARNESS_SCRIPT_DIR/manage_goal.py" assert-start-unit "$title" "$branch" "$target"
"$HARNESS_SCRIPT_DIR/start_codex_worktree.sh" "$title" "$branch" "$target"

(
  cd "$target"
  HARNESS_PROJECT_ROOT="$PWD" python3 "$HARNESS_SCRIPT_DIR/manage_goal.py" register-unit "$title" "$branch"
)

echo "goal unit ready: $target"
echo "next: cd $target"
echo "finish: ./scripts/finish_goal_unit.sh '<type>(scope): 작업 설명'"
