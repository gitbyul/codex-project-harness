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
import subprocess
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
        "scripts/bootstrap.sh",
        "scripts/create_run_artifact.sh",
        "scripts/create_worktree.sh",
        "scripts/verify.sh",
        "scripts/harness_commit.sh",
        "scripts/harness_status.sh",
        "scripts/start_task.sh",
        "scripts/start_codex_worktree.sh",
        "scripts/finish_task.sh",
        "scripts/harness_merge.sh",
        "scripts/harness_push.sh",
        "scripts/harness_publish.sh",
        "scripts/ensure_main_branch.sh",
        "scripts/install_github_cli.sh",
        "scripts/install_git_hooks.sh",
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
hook_errors: list[str] = []
for module, paths in module_paths.items():
    enabled = get_path(config, f"modules.{module}")
    if enabled is True or enabled == "true":
        for path in paths:
            if not (target_root / path).exists():
                missing.append(path)

githooks_enabled = get_path(config, "modules.githooks") in {True, "true"}
if githooks_enabled and (target_root / ".git").exists():
    expected_hooks_path = "githooks"
    try:
        configured_hooks_path = subprocess.check_output(
            ["git", "config", "--get", "core.hooksPath"],
            cwd=target_root,
            text=True,
            stderr=subprocess.DEVNULL,
        ).strip()
    except subprocess.CalledProcessError:
        configured_hooks_path = ""
    if configured_hooks_path != expected_hooks_path:
        hook_errors.append(
            f"core.hooksPath is '{configured_hooks_path or '<unset>'}', expected '{expected_hooks_path}'"
        )
    for hook in ("githooks/pre-commit", "githooks/commit-msg"):
        path = target_root / hook
        if path.exists() and not path.stat().st_mode & 0o111:
            hook_errors.append(f"hook is not executable: {hook}")
        if path.exists():
            body = path.read_text(encoding="utf-8", errors="ignore")
            expected_script = "pre-commit" if hook.endswith("pre-commit") else "commit-msg"
            expected_fragment = f'harness/githooks/{expected_script}'
            if expected_fragment not in body or "HARNESS_PROJECT_ROOT" not in body:
                hook_errors.append(f"hook wrapper content is not managed: {hook}")

status = "up-to-date" if source_matches and version_matches and not missing and not hook_errors else "update-required"
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
if hook_errors:
    print("- git hook installation issues:")
    for error in hook_errors:
        print(f"  - {error}")

if check_mode == "--check" and status != "up-to-date":
    raise SystemExit(1)
PY
