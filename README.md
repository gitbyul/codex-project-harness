# Codex Project Harness

범용 Codex 하네스 엔지니어링과 범용 프로젝트 매니저 스킬의 중앙 소스다. 각 제품 프로젝트는 이 저장소의 파일을 로컬에 설치해서 독립적으로 동작하고, 공통 업데이트가 필요할 때 이 저장소의 `installer/update.sh`를 실행해 동기화한다.

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

이미 설치된 프로젝트를 최신 공통 하네스로 갱신한다.

```bash
/Users/abyul/Desktop/project/codex-project-harness/installer/update.sh /path/to/project
```

여러 프로젝트를 한 번에 갱신하려면 `.codex-harness.yml`이 있는 프로젝트 루트를 스캔한다.

```bash
/Users/abyul/Desktop/project/codex-project-harness/installer/update-all.sh /Users/abyul/Desktop/project
```

## 프로젝트 설정

각 프로젝트 루트에는 `.codex-harness.yml`을 둔다.

```yaml
harness:
  source: /Users/abyul/Desktop/project/codex-project-harness
  version: local

modules:
  scripts: true
  githooks: true
  github_workflows: true
  generic_pm_skills: true
  docs_templates: false

project:
  name: example-project
  code_root: backend
  verify_command: ./scripts/verify.sh

local_overrides:
  skills:
    - project-specific-skill
```

`docs_templates`는 기본적으로 `false`를 권장한다. 프로젝트 문서는 도메인별 수정이 많기 때문에 중앙 템플릿으로 무조건 덮어쓰지 않는다.

## 업데이트 모델

이 저장소가 공통 파일의 원본이다.

```text
codex-project-harness
  -> project-a
  -> project-b
  -> project-c
```

공통 스킬이나 하네스 스크립트를 바꿀 때는 이 저장소에서 먼저 수정한다. 이후 각 프로젝트에서 `installer/update.sh`를 실행해 로컬 복사본을 갱신한다.

프로젝트별 수정은 각 프로젝트의 별도 파일에 둔다. 예를 들어 RVC 프로젝트 전용 스킬은 프로젝트의 `.codex/skills/rvc-*` 아래에 두고, 이 저장소의 `skills/generic-pm/`에는 넣지 않는다.

## 프로젝트별 검증 확장

중앙 `harness/scripts/verify.sh`는 공통 하네스 검사만 실행한다. 제품 도메인 문서, 코드 테스트, 런타임 검증처럼 프로젝트마다 다른 검사는 각 프로젝트의 `scripts/project_verify.sh`에 둔다.

예시:

```bash
#!/usr/bin/env bash
set -euo pipefail

python3 scripts/validate_docs.py
python3 scripts/check_project_docs.py

(
  cd backend
  python3 -m pytest
)
```

`installer/update.sh`는 `scripts/`를 삭제 동기화하지 않으므로 프로젝트별 `scripts/project_verify.sh`와 프로젝트 전용 검사 스크립트는 보존된다.

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

프로젝트에 설치한 뒤에는 프로젝트 루트에서 실행한다.

```bash
./scripts/verify.sh
```
