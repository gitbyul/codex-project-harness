#!/usr/bin/env bash
set -euo pipefail

HARNESS_SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="${HARNESS_PROJECT_ROOT:-$(pwd)}"
cd "$PROJECT_ROOT"
export HARNESS_PROJECT_ROOT="$PROJECT_ROOT"

if [ "$#" -lt 1 ]; then
  echo "usage: ./scripts/harness_commit.sh '<type>(scope): 한국어 설명'"
  echo "   or: ./scripts/harness_commit.sh -F commit-message.txt"
  exit 2
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
