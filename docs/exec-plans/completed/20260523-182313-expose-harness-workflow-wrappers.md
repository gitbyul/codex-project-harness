# Expose harness workflow wrappers

## 상태

진행 중

## 목표

- 소비 프로젝트에서 작업 시작, 완료, 커밋, 병합, 브랜치/worktree 정리 흐름을 `./scripts/*.sh` wrapper로 바로 실행할 수 있게 한다.
- 중앙 운영 스크립트가 `HARNESS_PROJECT_ROOT`를 기준으로 동작하게 만들어 wrapper 호출과 직접 호출을 모두 지원한다.

## 단계

- 운영 스크립트의 프로젝트 루트 인식 보강
- installer wrapper 생성 범위 확대
- start/finish workflow smoke test 추가
- 문서와 검증 갱신

## 관련 문서

- `README.md`
- `templates/docs/engineering/codex-skills.md`

## 영향 파일

- `harness/scripts/*.sh`
- `harness/scripts/check_git_hooks.py`
- `installer/update.sh`
- `installer/status.sh`
- `installer/smoke-test.sh`
- `installer/validate.sh`
- `manifest.json`
- `CHANGELOG.md`
- `AGENTS.md`
- `README.md`
- `templates/.codex-harness.yml`
- `templates/docs/engineering/codex-skills.md`
- `docs/exec-plans/**`
- `artifacts/runs/**`

## 아티팩트

- `artifacts/runs/20260523-182313-expose-harness-workflow-wrappers/run.md`

## 인수 기준

- 설치된 소비 프로젝트에 `start_task.sh`, `finish_task.sh`, `harness_merge.sh`, `finish_codex_worktree_task.sh` wrapper가 생성된다.
- wrapper로 `start_task.sh`와 `finish_task.sh`를 실행하는 smoke test가 통과한다.
- completed 실행 계획의 테스트 결과가 병합 게이트에서 요구하는 `통과` 상태로 갱신된다.
- 중앙 `./installer/validate.sh`가 통과한다.
- 소비 프로젝트 `.codex-harness.yml`에 중앙 manifest 버전이 기록되고 `harness_status.sh --check`로 업데이트 필요 여부를 확인할 수 있다.

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

- 운영 스크립트는 `HARNESS_PROJECT_ROOT`를 우선 사용하고, 없으면 현재 작업 디렉터리를 프로젝트 루트로 간주한다.
- 소비 프로젝트에는 중앙 스크립트를 직접 복사하지 않고 wrapper만 생성한다.
- 중앙 하네스 변경 추적은 `manifest.json` 버전과 `CHANGELOG.md`를 기준으로 관리한다.

## 위험

- 기존 소비 프로젝트의 `scripts/*.sh` 로컬 커스터마이징이 wrapper 재생성으로 덮어써질 수 있다. 중앙 관리 모듈 범위를 `.codex-harness.yml`로 명시하도록 문서화한다.
