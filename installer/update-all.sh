#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
search_root="${1:-/Users/abyul/Desktop/project}"

find "$search_root" -maxdepth 4 -name .codex-harness.yml -type f | while read -r config_file; do
  project_root="$(dirname "$config_file")"
  "$script_dir/update.sh" "$project_root"
done
