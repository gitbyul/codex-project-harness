# Codex Project Harness

범용 Codex 하네스 엔지니어링과 범용 프로젝트 매니저 스킬의 중앙 소스다. 각 제품 프로젝트는 이 저장소의 공통 원본을 직접 호출하는 wrapper/config만 둔다. 공통 하네스 스크립트와 범용 PM 스킬 원본은 이 저장소에만 둔다.

## 포함 범위

- 하네스 스크립트: `harness/scripts/`
- Git hook 템플릿: `harness/githooks/`
- GitHub Actions 템플릿: `harness/github-workflows/`
- 범용 PM 스킬: `skills/generic-pm/`
- 문서 템플릿: `templates/`
- 설치/업데이트 도구: `installer/`

## 포함하지 않는 것

- 프로젝트별 제품 요구사항
- 프로젝트별 도메인 스킬
- 프로젝트별 `planning/`
- 프로젝트별 운영, 품질, 권리 정책 문서
- 프로젝트별 코드 구조 결정

프로젝트별 내용은 각 프로젝트 저장소에 둔다. 이 저장소는 공통 하네스와 범용 PM 스킬만 관리한다.

## 기본 사용법

## 의존성

하네스 자체 실행에 필요한 기본 의존성:

- Git 2.x 이상
- Bash 호환 shell
- Python 3.10 이상
- 표준 Unix 도구: `find`, `sed`, `chmod`, `mktemp`, `sort`

권장 의존성:

- `rg`: 저장소 검색과 점검에 사용한다. 없으면 Git/쉘 기본 도구로 대체 가능하다.
- GitHub CLI `gh`: PR 생성, PR 병합, GitHub 인증이 필요한 흐름에 필요하다.

선택 의존성:

- macOS: Homebrew. `install_github_cli.sh`가 `gh` 설치에 사용한다.
- Debian/Ubuntu 계열 Linux: `apt-get`, `curl`, `sudo`.
- Fedora/RHEL 계열 Linux: `dnf` 또는 `yum`, `sudo`.
- Arch Linux: `pacman`, `sudo`.
- openSUSE: `zypper`, `sudo`.
- Windows Git Bash/MSYS/Cygwin: `winget`, `choco`, 또는 `scoop`.

`gh` 설치 helper:

```bash
./scripts/install_github_cli.sh --dry-run
./scripts/install_github_cli.sh
```

`gh`를 설치한 뒤 PR 흐름을 쓰려면 인증이 필요하다.

```bash
gh auth login
gh auth status
```

새 프로젝트 또는 기존 프로젝트에서 중앙 하네스를 설치한다.

```bash
$HARNESS_ROOT/installer/install.sh /path/to/project
```

이미 설치된 프로젝트의 wrapper/config를 최신 중앙 하네스 경로로 갱신한다.

```bash
$HARNESS_ROOT/installer/update.sh /path/to/project
```

설치 후 소비 프로젝트에는 다음 운영 wrapper가 생성된다.

```text
scripts/bootstrap.sh                    # 하네스 config와 기본 디렉터리/파일을 초기화한다.
scripts/create_run_artifact.sh          # 작업 실행 기록 artifact를 생성한다.
scripts/create_worktree.sh              # 작업 브랜치용 git worktree를 생성한다.
scripts/start_task.sh                   # 실행 계획과 run artifact를 만들고 작업을 시작한다.
scripts/start_codex_worktree.sh         # Codex 작업용 브랜치/worktree와 실행 계획을 함께 만든다.
scripts/finish_task.sh                  # 실행 계획과 artifact를 완료 상태로 정리한다.
scripts/start_goal.sh                   # 큰 목표를 시작하고 goal 상태를 기록한다.
scripts/start_goal_unit.sh              # goal 안의 작은 작업 단위를 새 worktree로 시작한다.
scripts/finish_goal_unit.sh             # goal unit을 완료, 커밋, main 병합, 정리한다.
scripts/finish_goal.sh                  # 모든 unit이 끝난 goal을 completed 문서로 정리한다.
scripts/harness_status.sh               # 설치 버전, source, wrapper, hook 상태를 점검한다.
scripts/harness_merge.sh                # 작업 브랜치를 main에 병합하고 브랜치/worktree를 정리한다.
scripts/harness_push.sh                 # 브랜치를 원격에 push하고 PR 준비 상태를 검증한다.
scripts/harness_publish.sh              # commit, push, PR 생성까지 publish 흐름을 수행한다.
scripts/ensure_main_branch.sh           # main 브랜치가 없으면 생성하고 기본 브랜치로 정리한다.
scripts/install_github_cli.sh           # OS별 패키지 매니저로 GitHub CLI 설치를 보조한다.
scripts/finish_codex_worktree_task.sh   # Codex worktree 작업을 commit, merge, cleanup까지 완료한다.
scripts/finish_codex_pr_task.sh         # Codex PR 작업을 검증, commit, push, PR 생성까지 완료한다.
scripts/open_pr.sh                      # 현재 브랜치에서 GitHub PR을 생성한다.
scripts/squash_merge_pr.sh              # GitHub PR을 squash merge하고 원격 브랜치를 정리한다.
scripts/verify.sh                       # 프로젝트 검증 명령을 실행한다.
scripts/install_git_hooks.sh            # 하네스 git hook을 설치하고 hooksPath를 설정한다.
```

권장 흐름은 작업 시작부터 병합 정리까지 하네스 명령으로 연결하는 것이다.

```bash
./scripts/start_codex_worktree.sh "작업 이름" task/example
cd ../<project>-task-example
./scripts/finish_codex_worktree_task.sh "feat(scope): 작업 설명"
```

위 흐름은 실행 계획과 run artifact를 만들고, 검증 후 커밋하며, `main`에 fast-forward 병합한 뒤 작업 브랜치와 source worktree 정리까지 수행한다.

커밋은 상위 완료 명령에서만 수행한다. 커밋만 따로 수행하면 push, PR, main 병합, 브랜치 삭제, worktree 정리가 누락될 수 있으므로 일반 작업은 `finish_codex_worktree_task.sh`, `finish_codex_pr_task.sh`, 또는 `harness_publish.sh`로 완료한다.

소비 프로젝트에는 독립 커밋 wrapper를 설치하지 않는다. 기존 설치본이 있으면 `installer/update.sh` 실행 시 제거된다.

큰 목표를 작은 작업 단위로 진행할 때는 goal wrapper를 사용한다.

```bash
./scripts/start_goal.sh "큰 목표 이름"
./scripts/start_goal_unit.sh "작은 작업 1"
cd ../<project>-task-작은-작업-1
# 작업
./scripts/finish_goal_unit.sh "feat(scope): 작은 작업 1"
cd ../<project>
./scripts/start_goal_unit.sh "작은 작업 2"
```

goal unit은 항상 깨끗한 `main` worktree에서 시작하며, 기존 unit의 branch/worktree가 남아 있거나 활성 실행 계획이 남아 있으면 다음 unit을 시작하지 않는다. 각 unit은 별도 branch/worktree, 실행 계획, run artifact, 커밋, `main` 병합, branch/worktree 정리를 하나의 완료 조건으로 가진다. 모든 unit이 완료되면 `finish_goal.sh`로 goal 문서를 `docs/goals/completed/`로 이동한다.

진행 중인 goal 상태는 다음 명령으로 확인한다.

```bash
./scripts/harness_status.sh --goal
```

`install.sh`, `update.sh`, `bootstrap.sh`는 Git 저장소의 초기 상태에서 `main` 브랜치를 로컬 주 브랜치로 보장한다. 아직 커밋이 없는 저장소는 unborn `main`으로 전환하고, 초기 `master` 브랜치에만 커밋이 있는 경우 `main`으로 rename한다. 이미 커밋이 있는 다른 브랜치는 프로젝트 정책일 수 있으므로 자동 변경하지 않고 안내만 한다.

원격 PR 기반 흐름을 사용할 때는 다음 명령을 쓴다.

```bash
./scripts/start_task.sh "작업 이름" task/example
# 작업
./scripts/finish_codex_pr_task.sh "feat(scope): 작업 설명"
```

이미 실행 계획을 완료했고 staged 변경을 직접 관리하고 있다면 커밋과 push/PR만 실행할 수도 있다.

```bash
./scripts/harness_publish.sh "feat(scope): 작업 설명" --push-only
./scripts/harness_publish.sh "feat(scope): 작업 설명" --pr
```

원격에 쓰기 전 흐름만 점검하려면 dry-run을 사용한다.

```bash
./scripts/harness_publish.sh "feat(scope): 작업 설명" --pr --dry-run
./scripts/open_pr.sh --base main --dry-run
```

GitHub CLI가 필요한 PR 흐름을 쓰기 전에 설치 helper를 실행할 수 있다.

```bash
./scripts/install_github_cli.sh --dry-run
./scripts/install_github_cli.sh
```

이 helper는 macOS Homebrew, Linux `apt-get`/`dnf`/`yum`/`pacman`/`zypper`, Windows `winget`/`choco`/`scoop`을 감지한다.

## 버전 및 업데이트 상태

중앙 하네스의 현재 버전은 `manifest.json`의 `version`이다. `installer/update.sh`는 소비 프로젝트의 `.codex-harness.yml`에 중앙 source와 version을 기록한다.

```yaml
harness:
  source: /path/to/codex-project-harness
  version: 0.8.0
```

소비 프로젝트가 어떤 하네스 버전을 사용 중인지 확인한다.

```bash
$HARNESS_ROOT/installer/status.sh /path/to/project
```

설치된 프로젝트 안에서는 wrapper로 확인할 수 있다.

```bash
./scripts/harness_status.sh
./scripts/harness_status.sh --check
```

`--check`는 중앙 버전과 다르거나 관리 파일이 누락된 경우, 또는 hook 관리가 켜져 있는데 `core.hooksPath=githooks`가 설정되지 않은 경우 실패한다. 여러 프로젝트 업데이트 여부와 hook 설치 상태를 추적하는 자동화에 사용할 수 있다.

여러 프로젝트를 한 번에 갱신하려면 `.codex-harness.yml`이 있는 프로젝트 루트를 스캔한다.

```bash
$HARNESS_ROOT/installer/update-all.sh /path/to/projects
```

## 프로젝트 설정

각 프로젝트 루트에는 `.codex-harness.yml`을 둔다.

```yaml
harness:
  source: /path/to/codex-project-harness
  version: 0.8.0
  ci:
    mode: local_path
    repository: ""
    ref: main

modules:
  scripts: true
  githooks: true
  github_workflows: false
  generic_pm_skills: true
  docs_templates: false

project:
  name: example-project
  code_root: ""
  verify_command: ""

architecture:
  python_source_roots: []
  forbidden_globals: []
  forbidden_route_calls: []

artifacts:
  required: true
  blocked_staged_suffixes:
    - .png
    - .jpg
    - .mp4
    - .onnx

quality:
  enabled: true
  commands: []
  required_plan_sections: true

local_overrides:
  skills:
    - project-specific-skill
```

`modules` 값은 `installer/update.sh`가 실제로 반영한다. 예를 들어 `github_workflows: false`면 `.github/workflows/verify.yml`을 생성하지 않고, `docs_templates: true`일 때만 중앙 문서 템플릿을 복사한다.

## 테스트/Mock 규칙

QA는 작업 단위의 마지막 수동 확인이 아니라 실행 계획, `./scripts/verify.sh`, run artifact에 연결된 필수 흐름이다. `.codex-harness.yml`의 `quality.commands`에 프로젝트별 품질 명령을 선언하면 `verify.sh`가 순서대로 실행한다.

```yaml
quality:
  enabled: true
  commands:
    - npm test
    - npm run test:integration
  required_plan_sections: true
```

현재 QA 설정은 다음 명령으로 확인한다.

```bash
./scripts/harness_status.sh --qa
```

하네스는 소비 프로젝트에 다음 개발/QA 규칙 파일을 제공한다.

```text
docs/engineering/development-quality-rules.md # 작업 단위별 개발 품질 기준과 quality gate 운영
docs/engineering/qa-test-strategy.md          # Small/Medium/Large 테스트 계층과 QA 기록 기준
docs/engineering/release-quality-gates.md     # main 병합/릴리스 전 품질 게이트
docs/engineering/backend-mocking-rules.md    # 백엔드 외부 경계 Fake/Stub 허용 기준과 금지 패턴
docs/engineering/frontend-mocking-rules.md   # 프론트엔드 MSW 중심 네트워크 mocking 기준과 금지 패턴
```

Mock/Stub/Fake/Fixture는 실제 구현과 계약 검증을 대체하지 않는다.

백엔드는 도메인 로직, 권한 판정, 상태 전이, DB repository/query/transaction을 Mock하지 않는다. 외부 결제, 이메일/SMS, OAuth, 외부 HTTP API, 시간, UUID/random, 메시지 큐, 파일 스토리지 같은 경계 의존성만 Fake/Stub 처리한다.

프론트엔드는 컴포넌트 내부 로직, 상태관리, form validation, 비즈니스 규칙을 Mock하지 않는다. API 응답은 API client 함수를 직접 Mock하기보다 MSW 같은 네트워크 레벨 mocking으로 제어한다.

규칙 파일은 `modules.docs_templates: true`인 프로젝트에 설치된다.

GitHub-hosted runner는 로컬 절대 경로의 중앙 하네스를 볼 수 없다. GitHub Actions를 쓰려면 중앙 하네스 저장소를 체크아웃하도록 설정한다.

```yaml
harness:
  source: /path/to/codex-project-harness
  version: 0.8.0
  ci:
    mode: checkout
    repository: owner/codex-project-harness
    ref: main

modules:
  github_workflows: true
```

`ci.mode: local_path`는 self-hosted runner처럼 `harness.source` 경로가 실제로 존재하는 환경에서만 사용한다.

`docs_templates`는 기본적으로 `false`를 권장한다. 프로젝트 문서는 도메인별 수정이 많기 때문에 중앙 템플릿으로 무조건 덮어쓰지 않는다.

## Git 강제 규칙

하네스는 로컬 hook, wrapper, CI, GitHub branch protection을 함께 사용한다.

로컬 hook 설치:

```bash
./scripts/install_git_hooks.sh
./scripts/harness_status.sh --check
```

로컬 hook이 강제하는 항목:

- `commit-msg`: 커밋 메시지 형식과 한국어 설명 확인
- `pre-commit`: main/master 직접 커밋 차단
- `pre-commit`: 실행계획 또는 completed plan 존재 확인
- `pre-commit`: staged 변경이 실행계획 영향 파일 범위 안인지 확인
- `pre-commit`: unstaged/untracked 혼입 차단
- `pre-commit`: secret, 아티팩트, Git hook, 공통 검증 실행

`--no-verify`는 로컬 hook을 우회할 수 있으므로 최종 강제는 CI와 branch protection에서 한다.

권장 GitHub branch protection:

- `main`에 직접 push 금지
- PR 필수
- required status checks 통과 필수
- branch 최신화 요구 또는 linear history 요구
- squash merge 또는 fast-forward 정책 중 하나를 프로젝트 정책으로 선택

권장 required checks:

```bash
./scripts/verify.sh
python3 <harness>/harness/scripts/check_commit_range.py --base origin/${base} --head HEAD
python3 <harness>/harness/scripts/check_pr_plan.py --base origin/${base} --branch HEAD
python3 <harness>/harness/scripts/check_test_handoff.py --base origin/${base} --branch HEAD
```

GitHub Actions를 중앙 하네스 checkout 방식으로 쓰려면 `.codex-harness.yml`에서 `modules.github_workflows: true`와 `harness.ci.mode: checkout`을 설정한 뒤 `installer/update.sh`를 다시 실행한다.

## 업데이트 모델

이 저장소가 공통 파일의 유일한 원본이다.

```text
codex-project-harness
  <- project-a wrapper/config
  <- project-b wrapper/config
  <- project-c wrapper/config
```

공통 스킬이나 하네스 스크립트를 바꿀 때는 이 저장소에서만 수정한다. 이후 각 프로젝트에서 `installer/update.sh`를 실행해 wrapper/config만 갱신한다.

프로젝트별 수정은 각 프로젝트의 별도 파일에 둔다. 예를 들어 특정 도메인 전용 스킬은 프로젝트의 `.codex/skills/<domain>-*` 아래에 둔다. 범용 PM 스킬 원본은 중앙 저장소에 두고, 소비 프로젝트에는 중앙 원본을 가리키는 얇은 wrapper만 생성한다.

## 프로젝트별 검증 확장

중앙 `harness/scripts/verify.sh`는 공통 하네스 검사만 실행한다. 제품 도메인 문서, 코드 테스트, 런타임 검증처럼 프로젝트마다 다른 검사는 `.codex-harness.yml`의 `project.verify_command`에 둔다. 기존 프로젝트 호환을 위해 `scripts/project_verify.sh`도 계속 지원한다.

예시:

```bash
#!/usr/bin/env bash
set -euo pipefail

python3 scripts/validate_docs.py
python3 scripts/check_project_docs.py

python3 -m pytest
```

`installer/update.sh`는 중앙 호출 wrapper와 선택된 모듈만 생성하므로 프로젝트별 검사 스크립트는 보존된다.

아키텍처 검사는 기본적으로 도메인 중립이며, 프로젝트가 필요할 때만 설정으로 켠다.

```yaml
architecture:
  python_source_roots:
    - src
  forbidden_globals:
    - mutable_runtime
  forbidden_route_calls:
    - direct_runtime_call
```

## 수정 보호 규칙

이 디렉터리의 파일은 중앙 원본이다. 다른 프로젝트 작업 중에 이 디렉터리를 직접 수정하면 안 된다.

허용되는 수정 조건:

1. 사용자가 명시적으로 `codex-project-harness` 자체를 수정하라고 요청한다.
2. 에이전트의 현재 작업 루트가 이 저장소 루트다.
3. 수정 전 중앙 하네스용 작업 브랜치 또는 명확한 실행 계획을 만든다.
4. 수정 후 이 저장소의 검증을 실행한다.

금지되는 수정:

- 개별 제품 프로젝트 작업 중 `../codex-project-harness`를 부수적으로 수정
- 프로젝트별 도메인 정책이나 제품 요구사항을 이 저장소에 추가
- 프로젝트 로컬 변경을 중앙 원본에 자동 역반영

업데이트 스크립트는 중앙 원본을 읽기만 하고 수정하지 않는다. 중앙 원본을 변경하려면 이 디렉터리에서 별도 작업으로 직접 수정해야 한다.

## 범용 PM 스킬

현재 제공하는 범용 PM 스킬:

- `product-discovery-synthesis`: 인터뷰, 피드백, 리서치 메모를 문제, 사용자, JTBD, 가정, 기회로 정리한다.
- `prd-development`: 문제, 사용자, 범위, 요구사항, 성공 기준, 리스크, 엔지니어링 핸드오프를 포함한 PRD를 작성하거나 개선한다.
- `deliver-user-stories`: 요구사항을 사용자 스토리와 Given/When/Then 인수 기준으로 분해한다.
- `roadmap-prioritization`: MVP 범위, 기능 후보, 백로그, 로드맵 항목의 우선순위와 트레이드오프를 정리한다.
- `release-readiness-review`: 릴리스 전 차단 이슈, 리스크, QA 근거, 운영 준비도, go/no-go 판단을 점검한다.
- `stakeholder-status-update`: 진행 상황, 차단 이슈, 결정 사항, 검증 결과를 이해관계자용 상태 업데이트로 정리한다.

프로젝트 특화 스킬은 각 프로젝트의 `.codex/skills/`에 둔다.

## 검증

중앙 하네스 자체 구조를 확인한다.

```bash
./installer/validate.sh
```

검증은 쉘/Python 문법 검사와 임시 Git 프로젝트에 대한 설치 smoke test를 함께 실행한다.

프로젝트에 설치한 뒤에는 프로젝트 루트에서 실행한다.

```bash
./scripts/verify.sh
```
