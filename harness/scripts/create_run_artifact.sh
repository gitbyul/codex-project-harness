#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

slug="${1:-run}"
timestamp="$(date +%Y%m%d-%H%M%S)"
run_id="${timestamp}-${slug}"
run_dir="artifacts/runs/${run_id}"

mkdir -p "$run_dir/logs" "$run_dir/screenshots" "$run_dir/images" "$run_dir/media" "$run_dir/traces"

cat > "$run_dir/run.md" <<EOF
# 작업 실행 기록: ${run_id}

## 작업 ID

${run_id}

## 실행 계획

- 

## 시작 시각

$(date -u +"%Y-%m-%dT%H:%M:%SZ")

## 종료 시각

- 

## 담당 에이전트

- 

## 변경 파일

- 

## 실행 명령

\`\`\`bash

\`\`\`

## 검증 결과

- 

## 아티팩트

- 로그: \`${run_dir}/logs/\`
- 스크린샷: \`${run_dir}/screenshots/\`
- 이미지: \`${run_dir}/images/\`
- 미디어: \`${run_dir}/media/\`
- 트레이스: \`${run_dir}/traces/\`

## 남은 이슈

- 

## 민감 정보 점검

- [ ] 대용량 바이너리, 모델 가중치, 토큰, 쿠키, 사용자 식별자가 Git에 staged 되지 않았다.
EOF

echo "$run_dir/run.md"
