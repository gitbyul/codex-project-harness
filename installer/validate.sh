#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

required_paths=(
  "README.md"
  "AGENTS.md"
  "manifest.json"
  "harness/scripts/verify.sh"
  "harness/scripts/ensure_main_branch.sh"
  "harness/scripts/install_github_cli.sh"
  "harness/scripts/manage_goal.py"
  "harness/scripts/start_goal.sh"
  "harness/scripts/start_goal_unit.sh"
  "harness/scripts/finish_goal_unit.sh"
  "harness/scripts/finish_goal.sh"
  "harness/scripts/check_quality_gates.py"
  "harness/scripts/check_qa_plan.py"
  "harness/scripts/harness_config.py"
  "harness/scripts/check_local_path_leaks.py"
  "harness/scripts/harness_commit.sh"
  "harness/githooks/pre-commit"
  "harness/githooks/commit-msg"
  "harness/github-workflows/verify.yml"
  "installer/status.sh"
  "installer/smoke-test.sh"
  "templates/.codex-harness.yml"
  "templates/docs/engineering/backend-mocking-rules.md"
  "templates/docs/engineering/frontend-mocking-rules.md"
  "templates/docs/engineering/development-quality-rules.md"
  "templates/docs/engineering/qa-test-strategy.md"
  "templates/docs/engineering/release-quality-gates.md"
)

for path in "${required_paths[@]}"; do
  if [ ! -e "$path" ]; then
    echo "missing required path: $path"
    exit 1
  fi
done

for skill in product-discovery-synthesis prd-development deliver-user-stories roadmap-prioritization release-readiness-review stakeholder-status-update; do
  if [ ! -f "skills/generic-pm/$skill/SKILL.md" ]; then
    echo "missing generic PM skill: $skill"
    exit 1
  fi
  if [ ! -f "skills/generic-pm/$skill/agents/openai.yaml" ]; then
    echo "missing OpenAI agent metadata for skill: $skill"
    exit 1
  fi
done

bash -n installer/install.sh installer/update.sh installer/update-all.sh installer/validate.sh installer/smoke-test.sh installer/status.sh
bash -n harness/scripts/*.sh
python3 -m py_compile harness/scripts/*.py
python3 harness/scripts/check_local_path_leaks.py
installer/smoke-test.sh

echo "codex-project-harness validation passed"
