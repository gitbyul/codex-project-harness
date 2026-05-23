#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

git config core.hooksPath githooks
chmod +x githooks/pre-commit githooks/commit-msg
chmod +x scripts/*.sh scripts/*.py

./scripts/verify.sh

echo "bootstrap complete"
echo "- core.hooksPath=$(git config --get core.hooksPath)"
