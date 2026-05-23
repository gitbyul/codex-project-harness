#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

git config core.hooksPath githooks
chmod +x githooks/pre-commit githooks/commit-msg

echo "configured core.hooksPath=githooks"
