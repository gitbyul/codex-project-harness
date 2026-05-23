# Enforce finish workflow for commits

## 상태

진행 중

## 목표

- 소비 프로젝트에서 `harness_commit.sh`를 최종 완료 명령처럼 사용해 커밋만 남기고 병합/push/PR 단계를 누락하는 일을 방지한다.
- 커밋은 기본적으로 `finish_codex_worktree_task.sh`, `finish_codex_pr_task.sh`, `harness_publish.sh` 같은 상위 명령을 통해 실행되도록 강제한다.

## 단계

- 현재 커밋/완료/병합 스크립트 경계 확인
- `harness_commit.sh` 직접 실행 차단 및 명시적 우회 규칙 추가
- 상위 명령이 내부 커밋을 호출할 때만 허용하도록 환경 변수 연결
- smoke test와 문서 업데이트
- 검증 후 하네스 방식으로 커밋/병합

## 관련 문서

- `README.md`
- `AGENTS.md`
- `templates/docs/engineering/codex-skills.md`
- `CHANGELOG.md`

## 영향 파일

- `harness/scripts/harness_commit.sh`
- `harness/scripts/harness_publish.sh`
- `harness/scripts/finish_codex_worktree_task.sh`
- `installer/smoke-test.sh`
- `README.md`
- `AGENTS.md`
- `CHANGELOG.md`
- `templates/docs/engineering/codex-skills.md`
- `manifest.json`
- `templates/.codex-harness.yml`
- `docs/exec-plans/**`
- `artifacts/runs/**`

## 아티팩트

- `artifacts/runs/20260523-191155-enforce-finish-workflow-for-commits/run.md`

## 인수 기준

- `harness_commit.sh` 직접 실행은 기본적으로 실패하고 상위 완료 명령을 안내한다.
- `HARNESS_ALLOW_DIRECT_COMMIT=1`과 `HARNESS_BYPASS_REASON`을 함께 제공하면 명시적으로 직접 커밋을 허용한다.
- 상위 명령은 내부적으로 `HARNESS_INTERNAL_COMMIT=1`을 설정해 기존 커밋 흐름을 유지한다.
- smoke test가 direct commit 차단 메시지를 검증한다.
- `./installer/validate.sh`가 통과한다.

## 구현 계획

1. 현재 문서와 스크립트를 확인한다.
2. 필요한 변경을 적용한다.
3. 검증을 실행하고 결과를 기록한다.

## 검증

```bash
./installer/validate.sh
```

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
- 우회는 가능하지만 반드시 이유를 기록하게 해서 예외를 추적한다.

## 위험

- 기존 자동화가 `harness_commit.sh`를 직접 호출하던 경우 실패할 수 있다. `harness_publish.sh` 또는 `finish_codex_*` 명령으로 전환해야 한다.
