# Backend Mocking Rules

백엔드 테스트는 실제 도메인 로직, DB 쿼리, transaction, API 계약을 우선 검증한다. Mock/Stub/Fake는 외부 경계 의존성을 통제하거나 실패 시나리오를 재현할 때만 사용한다.

## 원칙

- 도메인 로직, 권한 판정, 상태 전이, validation, repository query는 Mock하지 않는다.
- 외부 시스템 경계는 interface/port로 분리하고 테스트에서는 Fake adapter를 주입한다.
- 호출 횟수보다 결과, 저장 상태, 발행된 이벤트, 반환 API 응답을 검증한다.
- 공유 fixture는 최소화하고 테스트별 factory/builder로 필요한 데이터만 생성한다.
- 테스트 데이터는 운영 데이터를 복사하지 않는다.
- 날짜, timezone, UUID, random 값은 deterministic provider로 고정한다.
- API response fixture는 계약 schema와 일치해야 한다.

## 허용 대상

- 외부 결제 API
- 이메일/SMS provider
- OAuth/OpenID provider
- 외부 HTTP API
- Clock/time provider
- UUID/random provider
- 메시지 큐 publisher/consumer 경계
- 파일/object storage
- feature flag provider
- third-party webhook sender

## 금지 또는 지양 대상

- 도메인 서비스 내부 로직
- 권한 판정 로직
- 상태 전이 로직
- repository 자체
- ORM query
- transaction boundary
- controller response mapping
- serializer/deserializer
- validation rule

## 테스트 계층

### Unit Test

- 외부 의존성만 Fake/Stub 처리한다.
- 도메인 서비스와 use case는 실제 구현을 사용한다.
- assertion은 method 호출 횟수보다 결과와 상태 변경을 우선한다.

### Integration Test

- 실제 DB를 사용한다.
- migration, repository, ORM query, transaction rollback을 검증한다.
- 테스트별 독립 데이터를 factory로 생성한다.

### Contract Test

- request/response schema, status code, error shape를 검증한다.
- OpenAPI, GraphQL schema, protobuf, Zod/JSON Schema 중 프로젝트 계약 source와 연결한다.

### E2E Test

- 핵심 사용자 플로우만 실제 구성에 가깝게 검증한다.
- 외부 결제, 이메일, SMS, 파일 스토리지 같은 외부 경계만 Fake 처리한다.

## 테스트 데이터 규칙

- `test/factories/` 아래에 factory/builder를 둔다.
- `test/fixtures/`는 외부 API 응답이나 계약 샘플처럼 재사용이 필요한 최소 데이터만 둔다.
- fixture는 기본값만 포함하고, 테스트별 override로 필요한 필드만 바꾼다.
- shared global fixture 하나로 여러 테스트를 묶지 않는다.
- 테스트 간 DB 상태를 공유하지 않는다.
- 날짜/timezone은 고정한다.

## 권장 폴더 구조

```text
backend/
  src/
    domain/
    application/
    infrastructure/
      external/
        payment/
        email/
        storage/
        queue/
    interfaces/
  test/
    unit/
    integration/
    contract/
    e2e/
    factories/
    fakes/
      FakePaymentClient.ts
      FakeClock.ts
      FakeStorage.ts
    fixtures/
      external/
```

## Fake Adapter 예시

```ts
export interface PaymentClient {
  charge(input: ChargeInput): Promise<ChargeResult>;
}

export class RealPaymentClient implements PaymentClient {
  async charge(input: ChargeInput): Promise<ChargeResult> {
    return externalPaymentApi.charge(input);
  }
}

export class FakePaymentClient implements PaymentClient {
  private results = new Map<string, ChargeResult>();

  setResult(orderId: string, result: ChargeResult) {
    this.results.set(orderId, result);
  }

  async charge(input: ChargeInput): Promise<ChargeResult> {
    const result = this.results.get(input.orderId);
    if (!result) throw new Error("Fake payment result not configured");
    return result;
  }
}
```

```ts
it("결제 성공 시 주문을 paid 상태로 변경한다", async () => {
  const payment = new FakePaymentClient();
  const order = await orderFactory.create({ status: "pending" });

  payment.setResult(order.id, { status: "approved", transactionId: "tx_1" });

  await payOrderUseCase.execute({ orderId: order.id });

  const saved = await orderRepository.findById(order.id);
  expect(saved.status).toBe("paid");
});
```

## 리뷰 체크리스트

- [ ] Mock/Fake 대상이 외부 경계인가?
- [ ] 도메인 로직, 권한, 상태 전이, DB query를 Mock하지 않았는가?
- [ ] DB 관련 동작은 integration test에서 실제 DB로 검증했는가?
- [ ] assertion이 호출 횟수보다 결과/상태를 검증하는가?
- [ ] fixture가 API 계약과 일치하는가?
- [ ] 날짜/timezone/UUID/random이 deterministic한가?
