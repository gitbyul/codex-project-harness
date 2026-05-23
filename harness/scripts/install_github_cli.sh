#!/usr/bin/env bash
set -euo pipefail

dry_run="false"
while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run)
      dry_run="true"
      shift
      ;;
    -h|--help)
      echo "usage: ./scripts/install_github_cli.sh [--dry-run]"
      exit 0
      ;;
    *)
      echo "unknown argument: $1"
      echo "usage: ./scripts/install_github_cli.sh [--dry-run]"
      exit 2
      ;;
  esac
done

if command -v gh >/dev/null 2>&1; then
  echo "GitHub CLI already installed: $(gh --version | head -n 1)"
  exit 0
fi

run() {
  if [ "$dry_run" = "true" ]; then
    printf 'dry run:'
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}

run_shell() {
  if [ "$dry_run" = "true" ]; then
    echo "dry run: $*"
  else
    sh -c "$*"
  fi
}

os="$(uname -s 2>/dev/null || echo unknown)"
case "$os" in
  Darwin)
    if command -v brew >/dev/null 2>&1; then
      run brew install gh
    else
      echo "Homebrew가 필요합니다. 설치 후 다시 실행하세요: https://brew.sh"
      exit 1
    fi
    ;;
  Linux)
    if command -v apt-get >/dev/null 2>&1; then
      run_shell 'type -p curl >/dev/null || sudo apt-get update && sudo apt-get install -y curl'
      run_shell 'curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg'
      run sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
      run_shell 'echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null'
      run sudo apt-get update
      run sudo apt-get install -y gh
    elif command -v dnf >/dev/null 2>&1; then
      run sudo dnf install -y 'dnf-command(config-manager)'
      run sudo dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
      run sudo dnf install -y gh
    elif command -v yum >/dev/null 2>&1; then
      run sudo yum install -y yum-utils
      run sudo yum-config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
      run sudo yum install -y gh
    elif command -v pacman >/dev/null 2>&1; then
      run sudo pacman -S --needed github-cli
    elif command -v zypper >/dev/null 2>&1; then
      run sudo zypper install -y gh
    else
      echo "지원되는 Linux 패키지 매니저를 찾지 못했습니다: apt-get, dnf, yum, pacman, zypper"
      exit 1
    fi
    ;;
  MINGW*|MSYS*|CYGWIN*)
    if command -v winget >/dev/null 2>&1; then
      run winget install --id GitHub.cli --source winget
    elif command -v choco >/dev/null 2>&1; then
      run choco install gh -y
    elif command -v scoop >/dev/null 2>&1; then
      run scoop install gh
    else
      echo "Windows에서 winget, choco, scoop 중 하나가 필요합니다."
      exit 1
    fi
    ;;
  *)
    echo "지원하지 않는 OS입니다: $os"
    exit 1
    ;;
esac

if [ "$dry_run" = "true" ]; then
  echo "dry run complete: GitHub CLI installation command selected for $os"
else
  gh --version
fi
