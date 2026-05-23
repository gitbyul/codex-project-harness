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

새 프로젝트 또는 기존 프로젝트에서 중앙 하네스를 설치한다.

```bash
/Users/abyul/Desktop/project/codex-project-harness/installer/install.sh /path/to/project
```

이미 설치된 프로젝트의 wrapper/config를 최신 중앙 하네스 경로로 갱신한다.

```bash
/Users/abyul/Desktop/project/codex-project-harness/installer/update.sh /path/to/project
```

설치 후 소비 프로젝트에는 다음 운영 wrapper가 생성된다.

```text
scripts/start_task.sh
scripts/finish_task.sh
scripts/harness_commit.sh
scripts/harness_status.sh
scripts/harness_merge.sh
scripts/harness_push.sh
scripts/harness_publish.sh
scripts/finish_codex_worktree_task.sh
scripts/finish_codex_pr_task.sh
scripts/start_codex_worktree.sh
scripts/create_worktree.sh
scripts/open_pr.sh
scripts/squash_merge_pr.sh
scripts/verify.sh
```

권장 흐름은 작업 시작부터 병합 정리까지 하네스 명령으로 연결하는 것이다.

```bash
./scripts/start_codex_worktree.sh "작업 이름" task/example
cd ../<project>-task-example
./scripts/finish_codex_worktree_task.sh "feat(scope): 작업 설명"
```

위 흐름은 실행 계획과 run artifact를 만들고, 검증 후 커밋하며, `main`에 fast-forward 병합한 뒤 작업 브랜치와 source worktree 정리까지 수행한다.

`harness_commit.sh`는 저수준 내부 명령이다. 직접 실행하면 기본적으로 차단된다. 커밋만 수행하면 push, PR, main 병합, 브랜치 삭제, worktree 정리가 누락될 수 있으므로 일반 작업은 `finish_codex_worktree_task.sh`, `finish_codex_pr_task.sh`, 또는 `harness_publish.sh`로 완료한다. 예외적으로 커밋만 필요하면 `HARNESS_ALLOW_DIRECT_COMMIT=1`과 `HARNESS_BYPASS_REASON`을 함께 설정해야 한다.

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

## 버전 및 업데이트 상태

중앙 하네스의 현재 버전은 `manifest.json`의 `version`이다. `installer/update.sh`는 소비 프로젝트의 `.codex-harness.yml`에 중앙 source와 version을 기록한다.

```yaml
harness:
  source: /Users/abyul/Desktop/project/codex-project-harness
  version: 0.4.0
```

소비 프로젝트가 어떤 하네스 버전을 사용 중인지 확인한다.

```bash
/Users/abyul/Desktop/project/codex-project-harness/installer/status.sh /path/to/project
```

설치된 프로젝트 안에서는 wrapper로 확인할 수 있다.

```bash
./scripts/harness_status.sh
./scripts/harness_status.sh --check
```

`--check`는 중앙 버전과 다르거나 관리 파일이 누락된 경우 실패하므로, 여러 프로젝트 업데이트 여부를 추적하는 자동화에 사용할 수 있다.

여러 프로젝트를 한 번에 갱신하려면 `.codex-harness.yml`이 있는 프로젝트 루트를 스캔한다.

```bash
/Users/abyul/Desktop/project/codex-project-harness/installer/update-all.sh /Users/abyul/Desktop/project
```

## 프로젝트 설정

각 프로젝트 루트에는 `.codex-harness.yml`을 둔다.

```yaml
harness:
  source: /Users/abyul/Desktop/project/codex-project-harness
  version: 0.4.0
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

local_overrides:
  skills:
    - project-specific-skill
```

`modules` 값은 `installer/update.sh`가 실제로 반영한다. 예를 들어 `github_workflows: false`면 `.github/workflows/verify.yml`을 생성하지 않고, `docs_templates: true`일 때만 중앙 문서 템플릿을 복사한다.

GitHub-hosted runner는 로컬 절대 경로의 중앙 하네스를 볼 수 없다. GitHub Actions를 쓰려면 중앙 하네스 저장소를 체크아웃하도록 설정한다.

```yaml
harness:
  source: /Users/abyul/Desktop/project/codex-project-harness
  version: 0.4.0
  ci:
    mode: checkout
    repository: owner/codex-project-harness
    ref: main

modules:
  github_workflows: true
```

`ci.mode: local_path`는 self-hosted runner처럼 `harness.source` 경로가 실제로 존재하는 환경에서만 사용한다.

`docs_templates`는 기본적으로 `false`를 권장한다. 프로젝트 문서는 도메인별 수정이 많기 때문에 중앙 템플릿으로 무조건 덮어쓰지 않는다.

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
2. 에이전트의 현재 작업 루트가 `/Users/abyul/Desktop/project/codex-project-harness`다.
3. 수정 전 중앙 하네스용 작업 브랜치 또는 명확한 실행 계획을 만든다.
4. 수정 후 이 저장소의 검증을 실행한다.

금지되는 수정:

- 개별 제품 프로젝트 작업 중 `../codex-project-harness`를 부수적으로 수정
- 프로젝트별 도메인 정책이나 제품 요구사항을 이 저장소에 추가
- 프로젝트 로컬 변경을 중앙 원본에 자동 역반영

업데이트 스크립트는 중앙 원본을 읽기만 하고 수정하지 않는다. 중앙 원본을 변경하려면 이 디렉터리에서 별도 작업으로 직접 수정해야 한다.

## 범용 PM 스킬

현재 제공하는 범용 PM 스킬:

- `product-discovery-synthesis`
- `prd-development`
- `deliver-user-stories`
- `roadmap-prioritization`
- `release-readiness-review`
- `stakeholder-status-update`

프로젝트 특화 스킬은 각 프로젝트의 `.codex/skills/`에 둔다.

## 검증

중앙 하네스 자체 구조를 확인한다.

```bash
/Users/abyul/Desktop/project/codex-project-harness/installer/validate.sh
```

검증은 쉘/Python 문법 검사와 임시 Git 프로젝트에 대한 설치 smoke test를 함께 실행한다.

프로젝트에 설치한 뒤에는 프로젝트 루트에서 실행한다.

```bash
./scripts/verify.sh
```
