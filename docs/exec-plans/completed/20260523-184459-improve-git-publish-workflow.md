# Improve git publish workflow

## 상태

진행 중

## 목표

- 소비 프로젝트에서 스킬 의존 없이 CLI wrapper만으로 커밋, push, PR 생성, PR 병합까지 실행할 수 있게 한다.
- 각 단계가 하네스 검증과 실행계획/아티팩트 게이트를 통과하도록 연결한다.

## 단계

- 기존 commit/push/merge 스크립트 확인
- push 및 publish orchestration 스크립트 추가
- installer wrapper/status/smoke test 반영
- README/AGENTS/skill guide 문서 갱신
- 검증 후 하네스 방식으로 커밋 및 병합

## 관련 문서

- `README.md`
- `AGENTS.md`
- `templates/docs/engineering/codex-skills.md`
- `CHANGELOG.md`

## 영향 파일

- `harness/scripts/*.sh`
- `installer/update.sh`
- `installer/status.sh`
- `installer/smoke-test.sh`
- `installer/validate.sh`
- `README.md`
- `AGENTS.md`
- `CHANGELOG.md`
- `templates/docs/engineering/codex-skills.md`
- `manifest.json`
- `templates/.codex-harness.yml`
- `docs/exec-plans/**`
- `artifacts/runs/**`

## 아티팩트

- `artifacts/runs/20260523-184459-improve-git-publish-workflow/run.md`

## 인수 기준

- 소비 프로젝트에 `harness_push.sh`, `harness_publish.sh`, `finish_codex_pr_task.sh` wrapper가 설치된다.
- `harness_push.sh`는 검증과 PR plan/test handoff를 통과한 브랜치를 원격에 push한다.
- `harness_publish.sh`는 하네스 커밋 후 push 또는 PR 생성을 실행한다.
- smoke test가 새 wrapper 존재와 dry-run 경로를 검증한다.
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

- GitHub CLI가 필요한 PR 생성/병합과 단순 push를 분리한다.
- 원격 변경을 만드는 명령은 `--dry-run`을 지원해 설치 smoke test와 소비 프로젝트 사전 점검에 사용할 수 있게 한다.

## 위험

- 원격 push/PR 생성은 네트워크와 인증 상태에 의존하므로 smoke test는 dry-run으로 제한한다.
