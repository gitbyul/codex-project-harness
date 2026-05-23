#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${HARNESS_PROJECT_ROOT:-$(pwd)}"
cd "$PROJECT_ROOT"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "not a git worktree; skipping main branch setup"
  exit 0
fi

git config init.defaultBranch main

if git show-ref --verify --quiet refs/heads/main; then
  current="$(git branch --show-current || true)"
  if [ -z "$current" ] || [ "$current" = "main" ]; then
    git switch main >/dev/null 2>&1 || true
  fi
  echo "main branch already exists"
  exit 0
fi

if git rev-parse --verify HEAD >/dev/null 2>&1; then
  current="$(git branch --show-current || true)"
  if [ -z "$current" ]; then
    echo "repository has commits but no current branch; create/switch main manually"
    exit 1
  fi
  if [ "$current" = "master" ]; then
    git branch -m master main
    echo "renamed initial master branch to main"
    exit 0
  fi
  echo "repository already has commits on '$current'; not renaming to main automatically"
  echo "create main manually or run: git branch -m '$current' main"
  exit 0
fi

current_ref="$(git symbolic-ref --quiet --short HEAD 2>/dev/null || true)"
if [ "$current_ref" != "main" ]; then
  git symbolic-ref HEAD refs/heads/main
fi

echo "initialized unborn main branch"
