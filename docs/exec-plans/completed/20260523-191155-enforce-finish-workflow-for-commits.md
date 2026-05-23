# Enforce finish workflow for commits

## 상태

완료

## 목표

- 소비 프로젝트에서 독립 커밋 entrypoint를 최종 완료 명령처럼 사용해 커밋만 남기고 병합/push/PR 단계를 누락하는 일을 방지한다.
- 커밋은 기본적으로 `finish_codex_worktree_task.sh`, `finish_codex_pr_task.sh`, `harness_publish.sh` 같은 상위 명령을 통해 실행되도록 강제한다.

## 단계

- 현재 커밋/완료/병합 스크립트 경계 확인
- 독립 커밋 entrypoint 차단 규칙 추가
- 상위 명령이 내부 커밋을 호출할 때만 허용하도록 환경 변수 연결
- smoke test와 문서 업데이트
- 검증 후 하네스 방식으로 커밋/병합

## 관련 문서

- `README.md`
- `AGENTS.md`
- `templates/docs/engineering/codex-skills.md`
- `CHANGELOG.md`

## 영향 파일

- 내부 커밋 단계
- 완료/publish 스크립트
- smoke test
- README/AGENTS/CHANGELOG/skill guide
- version metadata
- execution plan과 run artifact

## 아티팩트

- `artifacts/runs/20260523-191155-enforce-finish-workflow-for-commits/run.md`

## 인수 기준

- 독립 커밋 entrypoint 직접 실행은 실패하고 상위 완료 명령을 안내한다.
- 상위 명령은 내부적으로 `HARNESS_INTERNAL_COMMIT=1`을 설정해 기존 커밋 흐름을 유지한다.
- smoke test가 독립 커밋 entrypoint 차단을 검증한다.
- `./installer/validate.sh`가 통과한다.

## 구현 계획

1. 현재 문서와 스크립트를 확인한다.
2. 필요한 변경을 적용한다.
3. 검증을 실행하고 결과를 기록한다.

## 검증

```bash
./installer/validate.sh
```

## QA 계획

- 테스트 계층:
  - [x] Small/unit
  - [x] Medium/integration
  - [ ] Contract
  - [x] Large/E2E smoke
- 수동 QA 필요 여부: 없음
- 회귀 위험: 소비 프로젝트 완료 흐름과 wrapper 설치 경로
- 검증할 사용자 플로우: 설치 후 완료 명령을 통한 검증, 커밋, 병합, 정리

## QA 결과

- 실행 명령: `./installer/validate.sh`
- 결과: 통과
- 남은 리스크: 기존 소비 프로젝트 자동화가 독립 커밋 entrypoint를 직접 호출하던 경우 상위 완료 명령으로 전환 필요

## 구현 담당

- Implementation Agent: Codex

## 테스트 담당

- Test Agent: 미정

## 테스트 명령

```bash
./installer/validate.sh
```

## 테스트 검증 결과

- 통과
## 결정 기록

- 저수준 커밋 명령은 유지하되 기본값을 “직접 사용 금지”로 바꾼다.
- 독립 커밋 entrypoint는 소비 프로젝트의 정상 완료 경로로 노출하지 않는다.

## 위험

- 기존 자동화가 독립 커밋 entrypoint를 직접 호출하던 경우 실패할 수 있다. `harness_publish.sh` 또는 `finish_codex_*` 명령으로 전환해야 한다.
