#!/usr/bin/env bash
set -euo pipefail

HARNESS_SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="${HARNESS_PROJECT_ROOT:-$(pwd)}"
cd "$PROJECT_ROOT"
export HARNESS_PROJECT_ROOT="$PROJECT_ROOT"

if [ "$#" -lt 1 ]; then
  echo "usage: ./scripts/harness_commit.sh '<type>(scope): 한국어 설명'"
  echo "   or: ./scripts/harness_commit.sh -F commit-message.txt"
  echo
  echo "이 명령은 저수준 커밋 명령입니다. 일반 작업 완료에는 다음 명령을 사용하세요:"
  echo "  ./scripts/finish_codex_worktree_task.sh '<type>(scope): 한국어 설명' [plan] [main]"
  echo "  ./scripts/finish_codex_pr_task.sh '<type>(scope): 한국어 설명' [plan] [main] [origin]"
  echo "  ./scripts/harness_publish.sh '<type>(scope): 한국어 설명' --push-only|--pr"
  exit 2
fi

if [ "${HARNESS_INTERNAL_COMMIT:-}" != "1" ] && [ "${HARNESS_ALLOW_DIRECT_COMMIT:-}" != "1" ]; then
  echo "direct harness_commit is blocked."
  echo "커밋만 수행하면 push/PR 또는 main 병합, 브랜치/worktree 정리가 누락될 수 있습니다."
  echo "일반 완료 흐름은 다음 중 하나를 사용하세요:"
  echo "- ./scripts/finish_codex_worktree_task.sh '<type>(scope): 한국어 설명' [plan] [main]"
  echo "- ./scripts/finish_codex_pr_task.sh '<type>(scope): 한국어 설명' [plan] [main] [origin]"
  echo "- ./scripts/harness_publish.sh '<type>(scope): 한국어 설명' --push-only|--pr"
  echo
  echo "정말 커밋만 해야 한다면 HARNESS_ALLOW_DIRECT_COMMIT=1 과 HARNESS_BYPASS_REASON을 함께 설정하세요."
  exit 1
fi

if [ "${HARNESS_ALLOW_DIRECT_COMMIT:-}" = "1" ] && [ -z "${HARNESS_BYPASS_REASON:-}" ]; then
  echo "HARNESS_ALLOW_DIRECT_COMMIT=1 사용 시 HARNESS_BYPASS_REASON을 반드시 입력해야 합니다."
  exit 1
fi

if [ "$1" = "-F" ]; then
  if [ "$#" -ne 2 ]; then
    echo "usage: ./scripts/harness_commit.sh -F commit-message.txt"
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
