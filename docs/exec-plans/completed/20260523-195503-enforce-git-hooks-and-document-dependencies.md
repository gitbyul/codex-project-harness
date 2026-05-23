# Enforce git hooks and document dependencies

## 상태

진행 중

## 목표

- 소비 프로젝트에서 hook 설치 상태까지 `harness_status.sh --check`로 강제 확인할 수 있게 한다.
- README에 하네스 사용 의존성과 GitHub branch protection/required checks 설정 가이드를 추가한다.
- 설치 smoke test가 hook 설치 상태 검증을 포함하도록 한다.

## 단계

- 현재 hook/status/installer 흐름 확인
- `installer/status.sh`에 `core.hooksPath` 검증 추가
- smoke test에서 hook 설치 후 status check 검증
- README/AGENTS/CHANGELOG/skill guide 문서 갱신
- 검증 후 하네스 방식 커밋/병합

## 관련 문서

- `README.md`
- `AGENTS.md`
- `CHANGELOG.md`
- `templates/docs/engineering/codex-skills.md`

## 영향 파일

- `installer/status.sh`
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

- `artifacts/runs/20260523-195503-enforce-git-hooks-and-document-dependencies/run.md`

## 인수 기준

- `scripts/harness_status.sh --check`가 관리 파일 누락뿐 아니라 hook 설치 설정도 확인한다.
- smoke test가 `install_git_hooks.sh` 실행 후 status check를 통과한다.
- README에 OS/런타임/도구/GitHub 설정 의존성이 명시된다.
- README에 branch protection과 required checks 권장 설정이 명시된다.
- `./installer/validate.sh`가 통과한다.

## 구현 계획

1. 현재 문서와 스크립트를 확인한다.
2. 필요한 변경을 적용한다.
3. 검증을 실행하고 결과를 기록한다.

## 검증

```bash
./scripts/verify.sh
```

## 구현 담당

- Implementation Agent: Codex

## 테스트 담당

- Test Agent: 미정

## 테스트 명령

```bash
./scripts/verify.sh
```

## 테스트 검증 결과

- 통과
## 결정 기록

- hook 파일 존재와 hook 설치 상태는 분리해서 보고한다. `--check`는 둘 중 하나라도 틀리면 실패한다.
- GitHub branch protection은 로컬 스크립트로 완전히 강제할 수 없으므로 README에서 저장소 설정 작업으로 명시한다.

## 위험

- 기존 프로젝트에서 hook을 의도적으로 비활성화한 경우 `modules.githooks: false`로 명시해야 status check가 통과한다.
