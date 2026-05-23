# Release Quality Gates

이 문서는 main 병합과 릴리스 전 통과해야 하는 품질 게이트를 정의한다. 프로젝트별 명령은 `.codex-harness.yml`에 선언하고, 하네스는 `./scripts/verify.sh`를 통해 동일한 기준을 로컬과 CI에서 실행한다.

## Main 병합 전 게이트

- 실행 계획이 완료 상태로 이동했다.
- run artifact에 검증 결과가 기록되었다.
- `./scripts/verify.sh`가 통과했다.
- configured quality commands가 모두 통과했다.
- API 계약 변경이 있다면 contract/schema 검증이 통과했다.
- Mock/Fixture 변경이 있다면 실제 계약과 일치함을 확인했다.
- branch/worktree 정리 가능한 상태다.

## 릴리스 전 게이트

- main 기준 verify가 통과한다.
- 핵심 smoke/E2E가 통과한다.
- migration 또는 데이터 변경이 있다면 rollback/복구 전략이 기록되어 있다.
- 운영 영향과 모니터링 항목이 기록되어 있다.
- 알려진 리스크와 미검증 영역이 release note 또는 run artifact에 남아 있다.

## CI 권장 구성

CI required check는 로컬 하네스와 동일하게 `./scripts/verify.sh`를 실행해야 한다.

```yaml
quality:
  enabled: true
  commands:
    - npm test
    - npm run test:integration
```

GitHub branch protection 또는 ruleset에서는 `main` 병합 전에 verify job을 required status check로 설정한다.

## 우회 기준

품질 게이트 우회는 기본적으로 금지한다. 불가피한 경우 다음을 기록해야 한다.

- 우회 사유
- 영향 범위
- 후속 보완 작업
- 승인자

## 체크리스트

- [ ] main 병합 전 `./scripts/verify.sh`가 통과했는가?
- [ ] quality commands가 통과했는가?
- [ ] contract/schema 변경 검증이 완료되었는가?
- [ ] Mock/Fixture가 실제 계약과 일치하는가?
- [ ] 릴리스 리스크와 미검증 영역이 기록되었는가?
