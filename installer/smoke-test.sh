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
test -x "$project/scripts/harness_status.sh"
test -x "$project/scripts/start_task.sh"
test -x "$project/scripts/finish_task.sh"
test -x "$project/scripts/harness_merge.sh"
test -x "$project/scripts/finish_codex_worktree_task.sh"
test -x "$project/githooks/pre-commit"
test -x "$project/githooks/commit-msg"
test -f "$project/.codex/skills/prd-development/SKILL.md"

(
  cd "$project"
  ./scripts/harness_status.sh --check
  ./scripts/verify.sh
  ./scripts/start_task.sh "Smoke workflow" task/smoke-workflow >/dev/null
  test -d docs/exec-plans/active
  test -d artifacts/runs
  ./scripts/verify.sh
  ./scripts/finish_task.sh >/dev/null
  test -d docs/exec-plans/completed
  test -z "$(find docs/exec-plans/active -maxdepth 1 -type f -name '*.md' -print)"
  test -n "$(find docs/exec-plans/completed -maxdepth 1 -type f -name '*.md' -print -quit)"
)

python3 "$harness_root/harness/scripts/harness_config.py" \
  --config "$project/.codex-harness.yml" \
  --get modules.github_workflows | grep -qx "false"

echo "codex-project-harness smoke test passed"
