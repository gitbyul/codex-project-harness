#!/usr/bin/env bash
set -euo pipefail

HARNESS_SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="${HARNESS_PROJECT_ROOT:-$(pwd)}"
cd "$PROJECT_ROOT"
export HARNESS_PROJECT_ROOT="$PROJECT_ROOT"

if [ "$#" -lt 1 ]; then
  echo "usage: ./scripts/start_goal.sh '<큰 목표 이름>'"
  exit 2
fi

python3 "$HARNESS_SCRIPT_DIR/manage_goal.py" start-goal "$1"
echo "next: ./scripts/start_goal_unit.sh '<작은 작업 이름>'"
