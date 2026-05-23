#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

plan="${1:-}"
if [ -z "$plan" ]; then
  mapfile -t active_plans < <(find docs/exec-plans/active -maxdepth 1 -type f -name '*.md' | sort)
  if [ "${#active_plans[@]}" -ne 1 ]; then
    echo "완료할 활성 실행 계획을 하나로 특정할 수 없습니다."
    echo "usage: ./scripts/finish_task.sh docs/exec-plans/active/<plan>.md"
    printf 'active plan: %s\n' "${active_plans[@]}"
    exit 1
  fi
  plan="${active_plans[0]}"
fi

if [ -z "$plan" ] || [ ! -f "$plan" ]; then
  echo "완료할 활성 실행 계획을 찾지 못했습니다."
  exit 1
fi

./scripts/verify.sh

completed="docs/exec-plans/completed/$(basename "$plan")"
python3 scripts/update_run_artifact.py --plan "$plan" --result "통과" --ended-now

sed -i.bak '0,/진행 중/s//완료/' "$plan"
rm -f "$plan.bak"
mv "$plan" "$completed"

echo "completed plan: $completed"
