#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
harness_root="$(cd "$script_dir/.." && pwd)"
target="${1:-$(pwd)}"
target_root="$(cd "$target" && pwd)"

if [ "$target_root" = "$harness_root" ]; then
  echo "Refusing to update codex-project-harness from its own installer."
  echo "Edit the central harness directly only from this directory with an explicit task."
  exit 1
fi

copy_dir() {
  local source_dir="$1"
  local target_dir="$2"
  mkdir -p "$target_dir"
  rsync -a "$source_dir"/ "$target_dir"/
}

copy_file() {
  local source_file="$1"
  local target_file="$2"
  mkdir -p "$(dirname "$target_file")"
  cp "$source_file" "$target_file"
}

if [ ! -f "$target_root/.codex-harness.yml" ]; then
  echo "Missing .codex-harness.yml in $target_root"
  echo "Run installer/install.sh first or create the config from templates/.codex-harness.yml."
  exit 1
fi

copy_dir "$harness_root/harness/scripts" "$target_root/scripts"
copy_dir "$harness_root/harness/githooks" "$target_root/githooks"
copy_file "$harness_root/harness/github-workflows/verify.yml" "$target_root/.github/workflows/verify.yml"

mkdir -p "$target_root/.codex/skills"
for skill_dir in "$harness_root"/skills/generic-pm/*; do
  [ -d "$skill_dir" ] || continue
  skill_name="$(basename "$skill_dir")"
  copy_dir "$skill_dir" "$target_root/.codex/skills/$skill_name"
done

if grep -q "docs_templates: true" "$target_root/.codex-harness.yml"; then
  copy_dir "$harness_root/templates/docs" "$target_root/docs"
fi

echo "Updated shared Codex harness files in $target_root"
