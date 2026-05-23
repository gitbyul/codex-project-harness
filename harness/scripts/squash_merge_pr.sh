#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${HARNESS_PROJECT_ROOT:-$(pwd)}"
cd "$PROJECT_ROOT"

pr_number="${1:-}"
if [ -z "$pr_number" ]; then
  echo "usage: ./scripts/squash_merge_pr.sh <pr-number>"
  exit 2
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "GitHub CLI(gh)가 필요합니다. gh 설치 후 다시 실행하세요."
  exit 1
fi

state="$(gh pr view "$pr_number" --json mergeStateStatus --jq .mergeStateStatus)"
if [ "$state" != "CLEAN" ] && [ "$state" != "HAS_HOOKS" ]; then
  echo "PR mergeStateStatus가 병합 가능 상태가 아닙니다: $state"
  exit 1
fi

gh pr merge "$pr_number" --squash --delete-branch
