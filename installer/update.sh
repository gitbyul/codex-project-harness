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

if [ ! -f "$target_root/.codex-harness.yml" ]; then
  echo "Missing .codex-harness.yml in $target_root"
  echo "Run installer/install.sh first or create the config from templates/.codex-harness.yml."
  exit 1
fi

mkdir -p "$target_root/scripts" "$target_root/githooks" "$target_root/.github/workflows"

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
        run: test -x "$harness_root/harness/scripts/verify.sh"
      - run: ./scripts/verify.sh
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

chmod +x "$target_root/scripts/verify.sh" \
  "$target_root/scripts/harness_commit.sh" \
  "$target_root/githooks/pre-commit" \
  "$target_root/githooks/commit-msg"

echo "Updated shared Codex harness wrappers in $target_root"
