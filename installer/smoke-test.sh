#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
harness_root="$(cd "$script_dir/.." && pwd)"
tmp_root="$(mktemp -d)"
trap 'rm -rf "$tmp_root"' EXIT

project="$tmp_root/example-project"
mkdir -p "$project"
(
  cd "$project"
  git init -q
)

"$script_dir/install.sh" "$project" >/dev/null

test -x "$project/scripts/verify.sh"
test -x "$project/scripts/harness_commit.sh"
test -x "$project/githooks/pre-commit"
test -x "$project/githooks/commit-msg"
test -f "$project/.codex/skills/prd-development/SKILL.md"

(
  cd "$project"
  ./scripts/verify.sh
)

python3 "$harness_root/harness/scripts/harness_config.py" \
  --config "$project/.codex-harness.yml" \
  --get modules.github_workflows | grep -qx "false"

echo "codex-project-harness smoke test passed"
