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
test -x "$project/scripts/harness_push.sh"
test -x "$project/scripts/harness_publish.sh"
test -x "$project/scripts/ensure_main_branch.sh"
test -x "$project/scripts/install_github_cli.sh"
test -x "$project/scripts/finish_codex_worktree_task.sh"
test -x "$project/scripts/finish_codex_pr_task.sh"
test -x "$project/githooks/pre-commit"
test -x "$project/githooks/commit-msg"
test -f "$project/.codex/skills/prd-development/SKILL.md"

(
  cd "$project"
  ./scripts/harness_status.sh --check
  test "$(git symbolic-ref --quiet --short HEAD)" = "main"
  ./scripts/ensure_main_branch.sh
  ./scripts/install_github_cli.sh --dry-run >/dev/null
  ./scripts/verify.sh
  ./scripts/start_task.sh "Smoke workflow" task/smoke-workflow >/dev/null
  test -d docs/exec-plans/active
  test -d artifacts/runs
  ./scripts/verify.sh
  ./scripts/finish_task.sh >/dev/null
  test -d docs/exec-plans/completed
  test -z "$(find docs/exec-plans/active -maxdepth 1 -type f -name '*.md' -print)"
  test -n "$(find docs/exec-plans/completed -maxdepth 1 -type f -name '*.md' -print -quit)"
  if ./scripts/harness_commit.sh "feat(smoke): 직접 커밋 차단" >/tmp/harness-direct-commit.out 2>&1; then
    echo "direct harness_commit should be blocked"
    exit 1
  fi
  grep -q "direct harness_commit is blocked" /tmp/harness-direct-commit.out
  ./scripts/harness_publish.sh "feat(smoke): 스모크 검증" --dry-run
)

python3 "$harness_root/harness/scripts/harness_config.py" \
  --config "$project/.codex-harness.yml" \
  --get modules.github_workflows | grep -qx "false"

echo "codex-project-harness smoke test passed"
