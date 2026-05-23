#!/usr/bin/env bash
set -euo pipefail

HARNESS_SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="${HARNESS_PROJECT_ROOT:-$(pwd)}"
cd "$PROJECT_ROOT"
export HARNESS_PROJECT_ROOT="$PROJECT_ROOT"

source_branch="${1:-$(git branch --show-current)}"
main_branch="${2:-main}"
created_source_worktree=""
original_source_worktree=""

cleanup() {
  if [ -n "$created_source_worktree" ] && [ -d "$created_source_worktree" ]; then
    git worktree remove "$created_source_worktree" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

if [ -z "$source_branch" ]; then
  echo "병합할 작업 브랜치를 찾지 못했습니다."
  exit 2
fi

case "$source_branch" in
  main|master)
    echo "main/master 브랜치는 자기 자신으로 병합할 수 없습니다."
    exit 1
    ;;
esac

branch_worktree() {
  local branch="$1"
  python3 - "$branch" <<'PY'
import subprocess
import sys

target = sys.argv[1]
output = subprocess.check_output(["git", "worktree", "list", "--porcelain"], text=True)
path = None
found = None
for line in output.splitlines():
    if line.startswith("worktree "):
        path = line.removeprefix("worktree ")
    elif line == f"branch refs/heads/{target}" and path:
        found = path
        break
print(found or "")
PY
}

source_worktree="$(branch_worktree "$source_branch")"
main_worktree="$(branch_worktree "$main_branch")"
original_source_worktree="$source_worktree"

if [ -z "$source_worktree" ]; then
  if ! git show-ref --verify --quiet "refs/heads/$source_branch"; then
    echo "작업 브랜치를 찾지 못했습니다: $source_branch"
    exit 1
  fi
  safe_branch="${source_branch//\//-}"
  source_worktree="/private/tmp/$(basename "$(pwd)")-$safe_branch-merge"
  if [ -e "$source_worktree" ]; then
    echo "임시 source worktree 경로가 이미 존재합니다: $source_worktree"
    echo "기존 경로를 정리하거나 작업 브랜치를 별도 worktree에 checkout하세요."
    exit 1
  fi
  git worktree add "$source_worktree" "$source_branch"
  created_source_worktree="$source_worktree"
  echo "created temporary source worktree: $source_worktree"
fi

if [ -z "$main_worktree" ]; then
  echo "main worktree를 찾지 못했습니다: $main_branch"
  exit 1
fi

python3 "$HARNESS_SCRIPT_DIR/check_worktree_clean.py" "$source_branch"
python3 "$HARNESS_SCRIPT_DIR/check_worktree_clean.py" "$main_branch"

(
  cd "$source_worktree"
  HARNESS_PROJECT_ROOT="$PWD" "$HARNESS_SCRIPT_DIR/verify.sh"
  HARNESS_PROJECT_ROOT="$PWD" python3 "$HARNESS_SCRIPT_DIR/check_pr_plan.py" --base "$main_branch" --branch "$source_branch"
  HARNESS_PROJECT_ROOT="$PWD" python3 "$HARNESS_SCRIPT_DIR/check_test_handoff.py" --base "$main_branch" --branch "$source_branch"
)

(
  cd "$main_worktree"
  git switch "$main_branch"
  if ! git merge --ff-only "$source_branch"; then
    echo "fast-forward 병합이 불가능합니다."
    echo "작업 브랜치를 최신 $main_branch 위로 rebase한 뒤 다시 실행하거나 PR 흐름을 사용하세요."
    exit 1
  fi
  HARNESS_PROJECT_ROOT="$PWD" "$HARNESS_SCRIPT_DIR/verify.sh"
)

if [ "$source_branch" != "$main_branch" ] && [ "$source_branch" != "main" ] && [ "$source_branch" != "master" ]; then
  cd "$main_worktree"
  cleanup_source_worktree="${original_source_worktree:-$created_source_worktree}"
  if [ -n "$cleanup_source_worktree" ] && [ -d "$cleanup_source_worktree" ]; then
    if git worktree remove "$cleanup_source_worktree"; then
      echo "removed source worktree: $cleanup_source_worktree"
      if [ "$cleanup_source_worktree" = "$created_source_worktree" ]; then
        created_source_worktree=""
      fi
    else
      echo "source worktree 자동 정리에 실패했습니다. 수동으로 확인하세요: git worktree remove \"$cleanup_source_worktree\""
    fi
  fi

  if git show-ref --verify --quiet "refs/heads/$source_branch"; then
    if git branch -d "$source_branch"; then
      echo "deleted merged branch: $source_branch"
    else
      echo "병합된 브랜치 자동 삭제에 실패했습니다. 수동으로 확인하세요: git branch -d \"$source_branch\""
    fi
  fi
fi

echo "merged $source_branch into $main_branch"
