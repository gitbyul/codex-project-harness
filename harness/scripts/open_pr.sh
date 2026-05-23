#!/usr/bin/env bash
set -euo pipefail

HARNESS_SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="${HARNESS_PROJECT_ROOT:-$(pwd)}"
cd "$PROJECT_ROOT"
export HARNESS_PROJECT_ROOT="$PROJECT_ROOT"

base="${1:-main}"
head="$(git branch --show-current)"

if [ -z "$head" ]; then
  echo "현재 브랜치를 확인할 수 없습니다."
  exit 1
fi

if [ "$head" = "$base" ]; then
  echo "base 브랜치에서는 PR을 만들 수 없습니다: $base"
  exit 1
fi

if ! git diff --quiet || ! git diff --cached --quiet || [ -n "$(git ls-files --others --exclude-standard)" ]; then
  echo "PR 생성 전 worktree가 깨끗해야 합니다."
  exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "GitHub CLI(gh)가 필요합니다. gh 설치 후 다시 실행하세요."
  exit 1
fi

"$HARNESS_SCRIPT_DIR/verify.sh"
python3 "$HARNESS_SCRIPT_DIR/check_pr_plan.py" --base "$base" --branch "$head"
python3 "$HARNESS_SCRIPT_DIR/check_test_handoff.py" --base "$base" --branch "$head"

git push -u origin "$head"

title="$(git log -1 --pretty=%s)"
body_file="$(mktemp)"
trap 'rm -f "$body_file"' EXIT

cat > "$body_file" <<EOF
## 요약

- 하네스 검증을 통과한 작업 브랜치입니다.

## 검증

\`\`\`bash
./scripts/verify.sh
python3 scripts/check_test_handoff.py --base ${base} --branch ${head}
\`\`\`

## 병합 조건

- required checks 통과
- 독립 테스트 담당 기록 확인
- 리뷰 승인
EOF

args=(pr create --base "$base" --head "$head" --title "$title" --body-file "$body_file" --draft)

if [ -n "${HARNESS_REVIEWERS:-}" ]; then
  args+=(--reviewer "$HARNESS_REVIEWERS")
fi

gh "${args[@]}"
