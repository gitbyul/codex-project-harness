#!/usr/bin/env bash
set -euo pipefail

HARNESS_SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HARNESS_ROOT="$(cd "$HARNESS_SCRIPT_DIR/../.." && pwd)"
PROJECT_ROOT="${HARNESS_PROJECT_ROOT:-$(pwd)}"
cd "$PROJECT_ROOT"

PYTHON_BIN="${PYTHON:-python3}"
if [ -z "${PYTHON:-}" ] && [ -x ".venv/bin/python" ]; then
  PYTHON_BIN=".venv/bin/python"
fi
case "$PYTHON_BIN" in
  /*) PYTHON_BIN_ABS="$PYTHON_BIN" ;;
  *) PYTHON_BIN_ABS="$PWD/$PYTHON_BIN" ;;
esac

export HARNESS_PROJECT_ROOT="$PROJECT_ROOT"

"$PYTHON_BIN" -m py_compile "$HARNESS_SCRIPT_DIR"/*.py
"$PYTHON_BIN" "$HARNESS_SCRIPT_DIR/guard_architecture.py"
"$PYTHON_BIN" "$HARNESS_SCRIPT_DIR/check_exec_plans.py"
"$PYTHON_BIN" "$HARNESS_SCRIPT_DIR/check_artifacts.py"
"$PYTHON_BIN" "$HARNESS_SCRIPT_DIR/check_secrets.py"
"$PYTHON_BIN" "$HARNESS_SCRIPT_DIR/check_git_hooks.py"

verify_command="$("$PYTHON_BIN" "$HARNESS_SCRIPT_DIR/harness_config.py" --config ".codex-harness.yml" --get project.verify_command)"
if [ "$verify_command" != "" ] && [ "$verify_command" != "./scripts/verify.sh" ] && [ "$verify_command" != "scripts/verify.sh" ]; then
  PYTHON="$PYTHON_BIN_ABS" bash -lc "$verify_command"
elif [ -x "scripts/project_verify.sh" ]; then
  PYTHON="$PYTHON_BIN_ABS" scripts/project_verify.sh
fi
