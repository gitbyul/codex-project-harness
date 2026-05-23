#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

PYTHON_BIN="${PYTHON:-python3}"
if [ -z "${PYTHON:-}" ] && [ -x ".venv/bin/python" ]; then
  PYTHON_BIN=".venv/bin/python"
fi
case "$PYTHON_BIN" in
  /*) PYTHON_BIN_ABS="$PYTHON_BIN" ;;
  *) PYTHON_BIN_ABS="$PWD/$PYTHON_BIN" ;;
esac

"$PYTHON_BIN" -m py_compile scripts/*.py
"$PYTHON_BIN" scripts/guard_architecture.py
"$PYTHON_BIN" scripts/check_exec_plans.py
"$PYTHON_BIN" scripts/check_artifacts.py
"$PYTHON_BIN" scripts/check_secrets.py
"$PYTHON_BIN" scripts/check_git_hooks.py

if [ -x "scripts/project_verify.sh" ]; then
  PYTHON="$PYTHON_BIN_ABS" scripts/project_verify.sh
fi
