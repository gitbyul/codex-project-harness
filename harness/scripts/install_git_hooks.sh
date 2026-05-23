#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${HARNESS_PROJECT_ROOT:-$(pwd)}"
cd "$PROJECT_ROOT"

hooks_path="githooks"
if [ ! -d "$hooks_path" ] && [ -d "harness/githooks" ]; then
  hooks_path="harness/githooks"
fi

git config core.hooksPath "$hooks_path"
chmod +x "$hooks_path/pre-commit" "$hooks_path/commit-msg"

echo "configured core.hooksPath=$hooks_path"
