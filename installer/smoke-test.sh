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
  git config user.email "codex-harness@example.invalid"
  git config user.name "Codex Harness"
)

"$script_dir/install.sh" "$project" >/dev/null

test -x "$project/scripts/verify.sh"
test ! -e "$project/scripts/harness_commit.sh"
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
test -x "$project/scripts/start_goal.sh"
test -x "$project/scripts/start_goal_unit.sh"
test -x "$project/scripts/finish_goal_unit.sh"
test -x "$project/scripts/finish_goal.sh"
test -x "$project/githooks/pre-commit"
test -x "$project/githooks/commit-msg"
test -f "$project/.codex/skills/prd-development/SKILL.md"

(
  cd "$project"
  if ./scripts/harness_status.sh --check >/tmp/harness-status-before-hooks.out 2>&1; then
    echo "harness_status should fail before hook installation"
    exit 1
  fi
  grep -q "core.hooksPath" /tmp/harness-status-before-hooks.out
  ./scripts/install_git_hooks.sh
  ./scripts/harness_status.sh --check
  ./scripts/harness_status.sh --qa | grep -q "QA workflow status:"
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
  ./scripts/harness_publish.sh "feat(smoke): 스모크 검증" --dry-run
  git switch main >/dev/null 2>&1 || git switch --orphan main >/dev/null
  git add -A
  HARNESS_ALLOW_MAIN_COMMIT=1 HARNESS_ALLOW_NO_PLAN=1 HARNESS_BYPASS_REASON="smoke test baseline" git commit -m "chore(smoke): 기준 커밋" >/dev/null
  ./scripts/start_goal.sh "Smoke goal" >/dev/null
  ./scripts/start_goal_unit.sh "Smoke goal unit" task/smoke-goal-unit "$tmp_root/smoke-goal-unit" >/dev/null
  test -d "$tmp_root/smoke-goal-unit"
  (
    cd "$tmp_root/smoke-goal-unit"
    printf 'goal unit\n' > goal-unit.txt
    ./scripts/finish_goal_unit.sh "feat(smoke): goal unit 검증" >/dev/null
  )
  test ! -d "$tmp_root/smoke-goal-unit"
  ! git show-ref --verify --quiet refs/heads/task/smoke-goal-unit
  grep -q "\\[x\\].*task/smoke-goal-unit" docs/goals/active/*.md
  ./scripts/harness_status.sh --goal | grep -q "active goal:"
  ./scripts/finish_goal.sh "chore(smoke): goal 완료" >/dev/null
  test -z "$(find docs/goals/active -maxdepth 1 -type f -name '*.md' -print 2>/dev/null)"
  test -n "$(find docs/goals/completed -maxdepth 1 -type f -name '*.md' -print -quit)"
)

(
  cd "$project"
  mv scripts/install_git_hooks.sh scripts/install_git_hooks.sh.bak
  if ./scripts/harness_status.sh --check >/tmp/harness-status-missing-wrapper.out 2>&1; then
    echo "harness_status should fail when a managed wrapper is missing"
    exit 1
  fi
  grep -q "scripts/install_git_hooks.sh" /tmp/harness-status-missing-wrapper.out
  mv scripts/install_git_hooks.sh.bak scripts/install_git_hooks.sh

  printf '#!/usr/bin/env bash\nexit 0\n' > githooks/pre-commit
  chmod +x githooks/pre-commit
  if ./scripts/harness_status.sh --check >/tmp/harness-status-corrupt-hook.out 2>&1; then
    echo "harness_status should fail when hook content is not managed"
    exit 1
  fi
  grep -q "hook wrapper content is not managed" /tmp/harness-status-corrupt-hook.out
)

python3 "$harness_root/harness/scripts/harness_config.py" \
  --config "$project/.codex-harness.yml" \
  --get modules.github_workflows | grep -qx "false"

echo "codex-project-harness smoke test passed"
