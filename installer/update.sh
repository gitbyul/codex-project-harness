#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
harness_root="$(cd "$script_dir/.." && pwd)"
target="${1:-$(pwd)}"
target_root="$(cd "$target" && pwd)"
config_file="$target_root/.codex-harness.yml"
harness_version="$(python3 - "$harness_root/manifest.json" <<'PY'
import json
import sys
from pathlib import Path

print(json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))["version"])
PY
)"

if [ "$target_root" = "$harness_root" ]; then
  echo "Refusing to update codex-project-harness from its own installer."
  echo "Edit the central harness directly only from this directory with an explicit task."
  exit 1
fi

if [ ! -f "$config_file" ]; then
  echo "Missing .codex-harness.yml in $target_root"
  echo "Run installer/install.sh first or create the config from templates/.codex-harness.yml."
  exit 1
fi

eval "$("$harness_root/harness/scripts/harness_config.py" --config "$config_file" --shell)"

if [ "$HARNESS_CONFIG_SOURCE" != "$harness_root" ] || [ "$HARNESS_CONFIG_VERSION" != "$harness_version" ]; then
  echo "Updating harness source/version in $config_file to $harness_root@$harness_version"
  python3 - "$config_file" "$harness_root" "$harness_version" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
source = sys.argv[2]
version = sys.argv[3]
lines = path.read_text(encoding="utf-8").splitlines()
inside_harness = False
seen_source = False
seen_version = False
for index, line in enumerate(lines):
    stripped = line.strip()
    if stripped == "harness:":
        inside_harness = True
        continue
    if inside_harness and line and not line.startswith(" ") and not line.startswith("\t"):
        break
    if inside_harness and stripped.startswith("source:"):
        indent = line[: len(line) - len(line.lstrip())]
        lines[index] = f"{indent}source: {source}"
        seen_source = True
    if inside_harness and stripped.startswith("version:"):
        indent = line[: len(line) - len(line.lstrip())]
        lines[index] = f"{indent}version: {version}"
        seen_version = True
insert_at = 1
if not seen_source:
    lines.insert(insert_at, f"  source: {source}")
    insert_at += 1
if not seen_version:
    lines.insert(insert_at, f"  version: {version}")
path.write_text("\n".join(lines) + "\n", encoding="utf-8")
PY
fi

if [ "$HARNESS_MODULE_SCRIPTS" = "true" ]; then
  mkdir -p "$target_root/scripts"
  cat > "$target_root/scripts/verify.sh" <<WRAPPER
#!/usr/bin/env bash
set -euo pipefail

repo_root="\$(cd "\$(dirname "\$0")/.." && pwd)"
harness_root="$harness_root"

HARNESS_PROJECT_ROOT="\$repo_root" "\$harness_root/harness/scripts/verify.sh"
WRAPPER

  cat > "$target_root/scripts/harness_commit.sh" <<WRAPPER
#!/usr/bin/env bash
set -euo pipefail

repo_root="\$(cd "\$(dirname "\$0")/.." && pwd)"
harness_root="$harness_root"

HARNESS_PROJECT_ROOT="\$repo_root" "\$harness_root/harness/scripts/harness_commit.sh" "\$@"
WRAPPER

  cat > "$target_root/scripts/harness_status.sh" <<WRAPPER
#!/usr/bin/env bash
set -euo pipefail

repo_root="\$(cd "\$(dirname "\$0")/.." && pwd)"
harness_root="$harness_root"

"\$harness_root/installer/status.sh" "\$repo_root" "\$@"
WRAPPER

  for script_name in \
    bootstrap \
    create_run_artifact \
    create_worktree \
    finish_codex_worktree_task \
    finish_codex_pr_task \
    finish_task \
    harness_merge \
    harness_publish \
    harness_push \
    install_git_hooks \
    open_pr \
    squash_merge_pr \
    start_codex_worktree \
    start_task
  do
    cat > "$target_root/scripts/${script_name}.sh" <<WRAPPER
#!/usr/bin/env bash
set -euo pipefail

repo_root="\$(cd "\$(dirname "\$0")/.." && pwd)"
harness_root="$harness_root"

HARNESS_PROJECT_ROOT="\$repo_root" "\$harness_root/harness/scripts/${script_name}.sh" "\$@"
WRAPPER
  done

  chmod +x "$target_root/scripts/"*.sh
fi

if [ "$HARNESS_MODULE_GITHOOKS" = "true" ]; then
  mkdir -p "$target_root/githooks"
  cat > "$target_root/githooks/pre-commit" <<WRAPPER
#!/usr/bin/env bash
set -euo pipefail

repo_root="\$(git rev-parse --show-toplevel)"
harness_root="$harness_root"

HARNESS_PROJECT_ROOT="\$repo_root" "\$harness_root/harness/githooks/pre-commit"
WRAPPER

  cat > "$target_root/githooks/commit-msg" <<WRAPPER
#!/usr/bin/env bash
set -euo pipefail

repo_root="\$(git rev-parse --show-toplevel)"
harness_root="$harness_root"

HARNESS_PROJECT_ROOT="\$repo_root" "\$harness_root/harness/githooks/commit-msg" "\$@"
WRAPPER

  chmod +x "$target_root/githooks/pre-commit" "$target_root/githooks/commit-msg"
fi

if [ "$HARNESS_MODULE_GENERIC_PM_SKILLS" = "true" ]; then
  skills_root="$target_root/.codex/skills"
  mkdir -p "$skills_root"
  for skill_dir in "$harness_root"/skills/generic-pm/*; do
    [ -d "$skill_dir" ] || continue
    skill="$(basename "$skill_dir")"
    mkdir -p "$skills_root/$skill"
    python3 - "$skill_dir/SKILL.md" "$skills_root/$skill/SKILL.md" "$skill" <<'PY'
from pathlib import Path
import sys

source = Path(sys.argv[1])
target = Path(sys.argv[2])
skill = sys.argv[3]
body = source.read_text(encoding="utf-8")
description = "Shared generic PM skill."
if body.startswith("---"):
    parts = body.split("---", 2)
    if len(parts) >= 3:
        for line in parts[1].splitlines():
            if line.startswith("description:"):
                description = line.split(":", 1)[1].strip()
                break
target.write_text(
    "---\n"
    f"name: {skill}\n"
    f"description: {description}\n"
    "---\n\n"
    f"# {skill}\n\n"
    f"This project uses the shared skill source at `{source}`.\n"
    "Open that file and follow its instructions for the current task.\n",
    encoding="utf-8",
)
PY
    if [ -d "$skill_dir/agents" ]; then
      mkdir -p "$skills_root/$skill/agents"
      cp "$skill_dir"/agents/* "$skills_root/$skill/agents/"
    fi
  done
fi

if [ "$HARNESS_MODULE_DOCS_TEMPLATES" = "true" ]; then
  mkdir -p "$target_root/docs"
  cp -R "$harness_root/templates/docs/." "$target_root/docs/"
fi

if [ "$HARNESS_MODULE_GITHUB_WORKFLOWS" = "true" ]; then
  mkdir -p "$target_root/.github/workflows"
  if [ "$HARNESS_CONFIG_CI_MODE" = "checkout" ]; then
    if [ "$HARNESS_CONFIG_CI_REPOSITORY" = "" ]; then
      echo "harness.ci.mode=checkout requires harness.ci.repository in $config_file"
      exit 1
    fi
    cat > "$target_root/.github/workflows/verify.yml" <<WRAPPER
name: verify

on:
  pull_request:
  push:

jobs:
  verify:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout project
        uses: actions/checkout@v4
      - name: Checkout shared harness
        uses: actions/checkout@v4
        with:
          repository: "$HARNESS_CONFIG_CI_REPOSITORY"
          ref: "$HARNESS_CONFIG_CI_REF"
          path: .codex-harness-cache
      - uses: actions/setup-python@v5
        with:
          python-version: "3.12"
      - run: python -m pip install --upgrade pip
      - run: HARNESS_PROJECT_ROOT="\$PWD" .codex-harness-cache/harness/scripts/verify.sh
      - name: Validate commit messages
        if: github.event_name == 'pull_request'
        run: HARNESS_PROJECT_ROOT="\$PWD" python3 .codex-harness-cache/harness/scripts/check_commit_range.py --base origin/\${{ github.base_ref }} --head HEAD
      - name: Validate PR execution plan
        if: github.event_name == 'pull_request'
        run: HARNESS_PROJECT_ROOT="\$PWD" python3 .codex-harness-cache/harness/scripts/check_pr_plan.py --base origin/\${{ github.base_ref }} --branch HEAD
      - name: Validate independent test handoff
        if: github.event_name == 'pull_request'
        run: HARNESS_PROJECT_ROOT="\$PWD" python3 .codex-harness-cache/harness/scripts/check_test_handoff.py --base origin/\${{ github.base_ref }} --branch HEAD
WRAPPER
  else
    cat > "$target_root/.github/workflows/verify.yml" <<WRAPPER
name: verify

on:
  pull_request:
  push:

jobs:
  verify:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: "3.12"
      - run: python -m pip install --upgrade pip
      - name: Check shared harness availability
        run: |
          test -x "$harness_root/harness/scripts/verify.sh" || {
            echo "Shared harness is configured for local_path CI but is not present on this runner."
            echo "Use harness.ci.mode=checkout with harness.ci.repository for GitHub-hosted runners."
            exit 1
          }
      - run: HARNESS_PROJECT_ROOT="\$PWD" "$harness_root/harness/scripts/verify.sh"
      - name: Validate commit messages
        if: github.event_name == 'pull_request'
        run: HARNESS_PROJECT_ROOT="\$PWD" python3 "$harness_root/harness/scripts/check_commit_range.py" --base origin/\${{ github.base_ref }} --head HEAD
      - name: Validate PR execution plan
        if: github.event_name == 'pull_request'
        run: HARNESS_PROJECT_ROOT="\$PWD" python3 "$harness_root/harness/scripts/check_pr_plan.py" --base origin/\${{ github.base_ref }} --branch HEAD
      - name: Validate independent test handoff
        if: github.event_name == 'pull_request'
        run: HARNESS_PROJECT_ROOT="\$PWD" python3 "$harness_root/harness/scripts/check_test_handoff.py" --base origin/\${{ github.base_ref }} --branch HEAD
WRAPPER
  fi
fi

echo "Updated shared Codex harness wrappers in $target_root"
