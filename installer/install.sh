#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
harness_root="$(cd "$script_dir/.." && pwd)"
target="${1:-$(pwd)}"
target_root="$(cd "$target" && pwd)"

if [ "$target_root" = "$harness_root" ]; then
  echo "Refusing to install codex-project-harness into itself."
  exit 1
fi

if [ ! -f "$target_root/.codex-harness.yml" ]; then
  cp "$harness_root/templates/.codex-harness.yml" "$target_root/.codex-harness.yml"
  project_name="$(basename "$target_root")"
  sed -i.bak "s/name: replace-me/name: $project_name/" "$target_root/.codex-harness.yml"
  rm -f "$target_root/.codex-harness.yml.bak"
fi

"$script_dir/update.sh" "$target_root"

echo "Installed shared Codex harness files in $target_root"
