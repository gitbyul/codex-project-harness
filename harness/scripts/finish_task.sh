#!/usr/bin/env bash
set -euo pipefail

HARNESS_SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="${HARNESS_PROJECT_ROOT:-$(pwd)}"
cd "$PROJECT_ROOT"
export HARNESS_PROJECT_ROOT="$PROJECT_ROOT"

plan="${1:-}"
if [ -z "$plan" ]; then
  active_plans=()
  while IFS= read -r active_plan; do
    active_plans+=("$active_plan")
  done < <(find docs/exec-plans/active -maxdepth 1 -type f -name '*.md' | sort)
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

mkdir -p docs/exec-plans/completed
"$HARNESS_SCRIPT_DIR/verify.sh"

completed="docs/exec-plans/completed/$(basename "$plan")"
python3 "$HARNESS_SCRIPT_DIR/update_run_artifact.py" --plan "$plan" --result "통과" --ended-now
python3 - "$plan" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
body = path.read_text(encoding="utf-8")

def replace_section(source: str, headings: tuple[str, ...], content: str) -> str:
    lines = source.splitlines()
    markers = {f"## {heading}" for heading in headings} | {f"### {heading}" for heading in headings}
    output: list[str] = []
    index = 0
    while index < len(lines):
        line = lines[index]
        output.append(line)
        if line in markers:
            index += 1
            while index < len(lines) and not lines[index].startswith("## ") and not lines[index].startswith("### "):
                index += 1
            output.append("")
            output.extend(content.splitlines())
            continue
        index += 1
    return "\n".join(output).rstrip() + "\n"

body = replace_section(body, ("테스트 검증 결과", "Test Result"), "- 통과")
path.write_text(body, encoding="utf-8")
PY

sed -i.bak '0,/진행 중/s//완료/' "$plan"
rm -f "$plan.bak"
mv "$plan" "$completed"

echo "completed plan: $completed"
