# Remove Local Path Leaks

## 상태

진행 중

## 목표

- 저장소에 남아 있는 개인 Mac 절대 경로와 사용자명 노출을 제거한다.
- 향후 생성되는 실행계획/템플릿이 절대 로컬 경로를 다시 기록하지 않도록 한다.

## 단계

- 저장소 전체에서 로컬 경로 패턴 검색
- README, AGENTS, 템플릿, 완료 실행계획, 스크립트 기본값 일반화
- 경로 노출 재발 방지를 위한 검증 추가
- 중앙 검증 실행 후 하네스 방식으로 커밋/병합

## 관련 문서

- `README.md`
- `AGENTS.md`
- `templates/.codex-harness.yml`
- `templates/docs/engineering/codex-skills.md`

## 영향 파일

- `README.md`
- `AGENTS.md`
- `templates/**`
- `docs/exec-plans/**`
- `harness/scripts/**`
- `installer/**`
- `artifacts/runs/**`

## 아티팩트

- `artifacts/runs/20260523-remove-local-path-leaks/run.md`

## 인수 기준

- 로컬 절대 경로와 개인 사용자명 경로가 저장소 텍스트에 남지 않는다.
- `start_task.sh`가 새 실행계획에 절대 프로젝트 경로를 쓰지 않는다.
- `./installer/validate.sh`가 통과한다.

## 구현 계획

1. 경로 노출 위치를 분류한다.
2. 문서와 템플릿은 `$HARNESS_ROOT`, `/path/to/...`, 상대 명령으로 대체한다.
3. 생성 스크립트는 상대 wrapper 명령을 기록하도록 수정한다.
4. 검증 명령을 실행하고 결과를 기록한다.

## 검증

```bash
python3 harness/scripts/check_local_path_leaks.py
./installer/validate.sh
```

## 구현 담당

- Implementation Agent: Codex

## 테스트 담당

- Test Agent: Harness validation

## 테스트 명령

```bash
python3 harness/scripts/check_local_path_leaks.py
./installer/validate.sh
```

## 테스트 검증 결과

- 통과
## 결정 기록

- 중앙 저장소 문서에는 개인 로컬 절대 경로 대신 `$HARNESS_ROOT` 또는 `/path/to/codex-project-harness`를 사용한다.
- 소비 프로젝트 config에는 install/update 시 실제 source가 기록될 수 있지만, 중앙 템플릿에는 placeholder만 둔다.

## 위험

- 기존 completed plan의 검증 명령을 수정하면 과거 기록이 일부 정규화된다. 민감 경로 제거를 우선한다.
