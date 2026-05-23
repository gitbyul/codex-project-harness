#!/usr/bin/env bash
set -euo pipefail

HARNESS_SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="${HARNESS_PROJECT_ROOT:-$(pwd)}"
cd "$PROJECT_ROOT"
export HARNESS_PROJECT_ROOT="$PROJECT_ROOT"

base="main"
remote="origin"
dry_run="false"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --base)
      base="${2:-}"
      shift 2
      ;;
    --remote)
      remote="${2:-}"
      shift 2
      ;;
    --dry-run)
      dry_run="true"
      shift
      ;;
    -h|--help)
      echo "usage: ./scripts/harness_push.sh [--base main] [--remote origin] [--dry-run]"
      exit 0
      ;;
    *)
      echo "unknown argument: $1"
      echo "usage: ./scripts/harness_push.sh [--base main] [--remote origin] [--dry-run]"
      exit 2
      ;;
  esac
done

branch="$(git branch --show-current)"
if [ -z "$branch" ]; then
  echo "현재 브랜치를 확인할 수 없습니다."
  exit 1
fi

case "$branch" in
  main|master)
    echo "main/master 브랜치는 작업 브랜치로 push하지 않습니다."
    exit 1
    ;;
esac

if ! git diff --quiet || ! git diff --cached --quiet || [ -n "$(git ls-files --others --exclude-standard)" ]; then
  echo "push 전 worktree가 깨끗해야 합니다. 먼저 하네스 커밋을 완료하세요."
  exit 1
fi

"$HARNESS_SCRIPT_DIR/verify.sh"
python3 "$HARNESS_SCRIPT_DIR/check_pr_plan.py" --base "$base" --branch "$branch"
python3 "$HARNESS_SCRIPT_DIR/check_test_handoff.py" --base "$base" --branch "$branch"

if [ "$dry_run" = "true" ]; then
  echo "dry run: git push -u $remote $branch"
  exit 0
fi

if ! git remote get-url "$remote" >/dev/null 2>&1; then
  echo "Git remote을 찾지 못했습니다: $remote"
  exit 1
fi

git push -u "$remote" "$branch"
