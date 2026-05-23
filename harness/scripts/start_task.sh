#!/usr/bin/env bash
set -euo pipefail

HARNESS_SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="${HARNESS_PROJECT_ROOT:-$(pwd)}"
cd "$PROJECT_ROOT"
export HARNESS_PROJECT_ROOT="$PROJECT_ROOT"

if [ "$#" -lt 1 ]; then
  echo "usage: ./scripts/start_task.sh '<작업 이름>' [branch-name]"
  exit 2
fi

title="$1"
slug="$(python3 "$HARNESS_SCRIPT_DIR/slugify.py" "$title")"
branch="${2:-task/$slug}"
timestamp="$(date +%Y%m%d-%H%M%S)"
plan="docs/exec-plans/active/${timestamp}-${slug}.md"

mkdir -p docs/exec-plans/active docs/exec-plans/completed artifacts/runs
run_path="$("$HARNESS_SCRIPT_DIR/create_run_artifact.sh" "$slug")"

current_branch="$(git branch --show-current)"
if [ "$current_branch" = "main" ] || [ "$current_branch" = "master" ]; then
  if ! git show-ref --verify --quiet "refs/heads/$branch"; then
    git switch -c "$branch"
  else
    git switch "$branch"
  fi
fi

cat > "$plan" <<EOF
# ${title}

## 상태

진행 중

## 목표

- 

## 단계

- 

## 관련 문서

- \`docs/index.md\`

## 영향 파일

- \`**\`

## 아티팩트

- \`${run_path}\`

## 인수 기준

- 

## 구현 계획

1. 현재 문서와 스크립트를 확인한다.
2. 필요한 변경을 적용한다.
3. 검증을 실행하고 결과를 기록한다.

## 검증

\`\`\`bash
./scripts/verify.sh
\`\`\`

## QA 계획

- 테스트 계층:
  - [ ] Small/unit
  - [ ] Medium/integration
  - [ ] Contract
  - [ ] Large/E2E smoke
- 수동 QA 필요 여부:
- 회귀 위험:
- 검증할 사용자 플로우:

## QA 결과

- 실행 명령:
- 결과:
- 남은 리스크:

## 구현 담당

- Implementation Agent: Codex

## 테스트 담당

- Test Agent: 미정

## 테스트 명령

\`\`\`bash
./scripts/verify.sh
\`\`\`

## 테스트 검증 결과

- 미완료

## 결정 기록

- 

## 위험

- 
EOF

echo "created plan: $plan"
echo "created artifact: $run_path"
echo "current branch: $(git branch --show-current)"
