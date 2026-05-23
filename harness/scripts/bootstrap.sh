#!/usr/bin/env bash
set -euo pipefail

HARNESS_SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="${HARNESS_PROJECT_ROOT:-$(pwd)}"
cd "$PROJECT_ROOT"
export HARNESS_PROJECT_ROOT="$PROJECT_ROOT"

git config core.hooksPath githooks
chmod +x githooks/pre-commit githooks/commit-msg
chmod +x scripts/*.sh scripts/*.py

"$HARNESS_SCRIPT_DIR/verify.sh"

echo "bootstrap complete"
echo "- core.hooksPath=$(git config --get core.hooksPath)"
