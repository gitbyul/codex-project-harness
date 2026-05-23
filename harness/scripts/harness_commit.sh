#!/usr/bin/env bash
set -euo pipefail

HARNESS_SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="${HARNESS_PROJECT_ROOT:-$(pwd)}"
cd "$PROJECT_ROOT"
export HARNESS_PROJECT_ROOT="$PROJECT_ROOT"

if [ "$#" -lt 1 ]; then
  echo "internal commit step requires a commit message."
  echo
  echo "일반 작업 완료에는 다음 명령을 사용하세요:"
  echo "  ./scripts/finish_codex_worktree_task.sh '<type>(scope): 한국어 설명' [plan] [main]"
  echo "  ./scripts/finish_codex_pr_task.sh '<type>(scope): 한국어 설명' [plan] [main] [origin]"
  echo "  ./scripts/harness_publish.sh '<type>(scope): 한국어 설명' --push-only|--pr"
  exit 2
fi

if [ "${HARNESS_INTERNAL_COMMIT:-}" != "1" ]; then
  echo "internal commit step is blocked outside the normal completion flow."
  echo "커밋만 수행하면 push/PR 또는 main 병합, 브랜치/worktree 정리가 누락될 수 있습니다."
  echo "일반 완료 흐름은 다음 중 하나를 사용하세요:"
  echo "- ./scripts/finish_codex_worktree_task.sh '<type>(scope): 한국어 설명' [plan] [main]"
  echo "- ./scripts/finish_codex_pr_task.sh '<type>(scope): 한국어 설명' [plan] [main] [origin]"
  echo "- ./scripts/harness_publish.sh '<type>(scope): 한국어 설명' --push-only|--pr"
  exit 1
fi

if [ "$1" = "-F" ]; then
  if [ "$#" -ne 2 ]; then
    echo "usage: internal commit step -F commit-message.txt"
    exit 2
  fi
  message_file="$2"
  python3 "$HARNESS_SCRIPT_DIR/check_commit_message.py" "$message_file"
  python3 "$HARNESS_SCRIPT_DIR/check_commit_ready.py"
  git commit -F "$message_file"
  exit 0
fi

message="$1"
message_file="$(mktemp)"
trap 'rm -f "$message_file"' EXIT
printf '%s\n' "$message" > "$message_file"
python3 "$HARNESS_SCRIPT_DIR/check_commit_message.py" "$message_file"
python3 "$HARNESS_SCRIPT_DIR/check_commit_ready.py"

git commit -m "$message"
