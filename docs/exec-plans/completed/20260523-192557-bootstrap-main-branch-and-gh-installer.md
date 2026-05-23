# Bootstrap main branch and gh installer

## 상태

진행 중

## 목표

- 새 Git 저장소 또는 초기 브랜치 상태에서 하네스 install/update 시 `main` 브랜치를 로컬 주 브랜치로 보장한다.
- 소비 프로젝트에서 OS별 GitHub CLI(`gh`) 설치 명령을 하네스 wrapper로 확인/실행할 수 있게 한다.

## 단계

- 초기 Git 브랜치 보장 스크립트 추가
- installer install/update/bootstrap에 main 브랜치 보장 연결
- OS별 `gh` 설치 helper 추가 및 wrapper 생성
- smoke test와 문서 갱신
- 검증 후 하네스 방식으로 커밋/병합

## 관련 문서

- `README.md`
- `AGENTS.md`
- `CHANGELOG.md`
- `templates/docs/engineering/codex-skills.md`

## 영향 파일

- `harness/scripts/ensure_main_branch.sh`
- `harness/scripts/install_github_cli.sh`
- `harness/scripts/bootstrap.sh`
- `installer/install.sh`
- `installer/update.sh`
- `installer/status.sh`
- `installer/smoke-test.sh`
- `installer/validate.sh`
- `README.md`
- `AGENTS.md`
- `CHANGELOG.md`
- `templates/docs/engineering/codex-skills.md`
- `templates/.codex-harness.yml`
- `manifest.json`
- `docs/exec-plans/**`
- `artifacts/runs/**`

## 아티팩트

- `artifacts/runs/20260523-192557-bootstrap-main-branch-and-gh-installer/run.md`

## 인수 기준

- 새 `git init` 저장소에 설치하면 현재 브랜치가 `main`이 된다.
- 이미 `main`이 있는 저장소는 변경 없이 통과한다.
- 기존 커밋이 있는 다른 브랜치 저장소는 자동 rename하지 않고 안내 후 보수적으로 유지한다.
- `install_github_cli.sh --dry-run`이 macOS/Linux/Windows 계열 설치 지침을 제공한다.
- 소비 프로젝트에 `scripts/install_github_cli.sh` wrapper가 생성된다.
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

- 초기 저장소에 대해서만 `main`을 자동 생성/전환한다. 이미 커밋된 비-main 브랜치는 프로젝트 정책일 수 있으므로 자동 변경하지 않는다.
- `gh` 설치는 자동 강제하지 않고 helper로 제공한다. `--dry-run`으로 명령 확인 후 실행할 수 있게 한다.

## 위험

- OS별 패키지 매니저가 없는 환경에서는 설치 helper가 안내만 하고 실패할 수 있다. 이 경우 공식 GitHub CLI 설치 문서 또는 수동 설치가 필요하다.
