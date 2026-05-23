#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
harness_root="$(cd "$script_dir/.." && pwd)"
target="${1:-$(pwd)}"
check_mode="${2:-}"
target_root="$(cd "$target" && pwd)"
config_file="$target_root/.codex-harness.yml"

if [ ! -f "$config_file" ]; then
  echo "codex harness status: not installed"
  echo "- project: $target_root"
  echo "- missing: .codex-harness.yml"
  exit 1
fi

python3 - "$harness_root" "$target_root" "$check_mode" <<'PY'
from __future__ import annotations

import json
import sys
from pathlib import Path

harness_root = Path(sys.argv[1]).resolve()
target_root = Path(sys.argv[2]).resolve()
check_mode = sys.argv[3]
sys.path.insert(0, str(harness_root / "harness" / "scripts"))

from harness_config import get_path, parse_config  # noqa: E402

config = parse_config(target_root / ".codex-harness.yml")
manifest = json.loads((harness_root / "manifest.json").read_text(encoding="utf-8"))

installed_source = str(get_path(config, "harness.source"))
installed_version = str(get_path(config, "harness.version"))
current_version = str(manifest["version"])
source_matches = installed_source == str(harness_root)
version_matches = installed_version == current_version

module_paths = {
    "scripts": [
        "scripts/verify.sh",
        "scripts/harness_commit.sh",
        "scripts/start_task.sh",
        "scripts/finish_task.sh",
        "scripts/harness_merge.sh",
        "scripts/harness_push.sh",
        "scripts/harness_publish.sh",
        "scripts/ensure_main_branch.sh",
        "scripts/install_github_cli.sh",
        "scripts/finish_codex_worktree_task.sh",
        "scripts/finish_codex_pr_task.sh",
        "scripts/open_pr.sh",
        "scripts/squash_merge_pr.sh",
    ],
    "githooks": ["githooks/pre-commit", "githooks/commit-msg"],
    "github_workflows": [".github/workflows/verify.yml"],
    "generic_pm_skills": [".codex/skills/prd-development/SKILL.md"],
    "docs_templates": ["docs/engineering/codex-skills.md"],
}

missing: list[str] = []
for module, paths in module_paths.items():
    enabled = get_path(config, f"modules.{module}")
    if enabled is True or enabled == "true":
        for path in paths:
            if not (target_root / path).exists():
                missing.append(path)

status = "up-to-date" if source_matches and version_matches and not missing else "update-required"
print(f"codex harness status: {status}")
print(f"- project: {target_root}")
print(f"- configured source: {installed_source}")
print(f"- current source: {harness_root}")
print(f"- configured version: {installed_version}")
print(f"- current version: {current_version}")
print(f"- source matches: {'yes' if source_matches else 'no'}")
print(f"- version matches: {'yes' if version_matches else 'no'}")
if missing:
    print("- missing managed files:")
    for path in missing:
        print(f"  - {path}")

if check_mode == "--check" and status != "up-to-date":
    raise SystemExit(1)
PY
