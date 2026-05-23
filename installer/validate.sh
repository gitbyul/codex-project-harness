#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

required_paths=(
  "README.md"
  "AGENTS.md"
  "manifest.json"
  "harness/scripts/verify.sh"
  "harness/scripts/harness_config.py"
  "harness/scripts/harness_commit.sh"
  "harness/githooks/pre-commit"
  "harness/githooks/commit-msg"
  "harness/github-workflows/verify.yml"
  "installer/status.sh"
  "installer/smoke-test.sh"
  "templates/.codex-harness.yml"
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
installer/smoke-test.sh

echo "codex-project-harness validation passed"
