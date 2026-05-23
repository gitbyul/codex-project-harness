#!/usr/bin/env bash
set -euo pipefail

HARNESS_SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="${HARNESS_PROJECT_ROOT:-$(pwd)}"
cd "$PROJECT_ROOT"
export HARNESS_PROJECT_ROOT="$PROJECT_ROOT"

if [ "$#" -lt 1 ]; then
  echo "usage: ./scripts/harness_publish.sh '<type>(scope): 한국어 설명' [--push-only|--pr] [--base main] [--remote origin] [--dry-run]"
  exit 2
fi

message="$1"
shift
mode="push"
base="main"
remote="origin"
dry_run="false"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --push-only)
      mode="push"
      shift
      ;;
    --pr)
      mode="pr"
      shift
      ;;
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
      echo "usage: ./scripts/harness_publish.sh '<type>(scope): 한국어 설명' [--push-only|--pr] [--base main] [--remote origin] [--dry-run]"
      exit 0
      ;;
    *)
      echo "unknown argument: $1"
      echo "usage: ./scripts/harness_publish.sh '<type>(scope): 한국어 설명' [--push-only|--pr] [--base main] [--remote origin] [--dry-run]"
      exit 2
      ;;
  esac
done

message_file="$(mktemp)"
trap 'rm -f "$message_file"' EXIT
printf '%s\n' "$message" > "$message_file"
python3 "$HARNESS_SCRIPT_DIR/check_commit_message.py" "$message_file"

if [ "$dry_run" = "true" ]; then
  echo "dry run: git add -A"
  echo "dry run: internal commit step \"$message\""
  if [ "$mode" = "pr" ]; then
    echo "dry run: ./scripts/open_pr.sh --base $base --remote $remote"
  else
    echo "dry run: ./scripts/harness_push.sh --base $base --remote $remote"
  fi
  exit 0
fi

git add -A
HARNESS_INTERNAL_COMMIT=1 "$HARNESS_SCRIPT_DIR/harness_commit.sh" "$message"

if [ "$mode" = "pr" ]; then
  "$HARNESS_SCRIPT_DIR/open_pr.sh" --base "$base" --remote "$remote"
else
  "$HARNESS_SCRIPT_DIR/harness_push.sh" --base "$base" --remote "$remote"
fi
