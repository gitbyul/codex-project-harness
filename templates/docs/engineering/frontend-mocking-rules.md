# Frontend Mocking Rules

프론트엔드 테스트는 컴포넌트, 상태관리, form validation, 비즈니스 규칙을 실제 구현으로 검증한다. Mock/Stub은 API 네트워크 경계와 실패/빈 데이터/권한별 응답 재현에만 사용한다.

## 원칙

- API client 함수를 직접 Mock하기보다 MSW 같은 네트워크 레벨 mocking을 사용한다.
- 컴포넌트 내부 로직, 상태관리 로직, form validation, 비즈니스 규칙은 Mock하지 않는다.
- handler와 fixture는 API 계약 schema/type과 일치해야 한다.
- unhandled request는 error로 처리한다.
- 테스트마다 handler를 reset한다.
- fixture는 최소 기본값만 제공하고 화면별 override를 사용한다.
- 테스트는 implementation detail보다 사용자 관찰 결과를 검증한다.

## 허용 대상

- 아직 준비되지 않은 API
- 외부 API
- 서버 오류 응답
- 빈 목록/빈 상태
- nullable field
- 지연 응답
- 권한 없음/인증 만료
- pagination edge case
- rate limit
- 파일 업로드 실패

## 금지 또는 지양 대상

- 컴포넌트 내부 함수
- 상태관리 reducer/store logic
- form validation logic
- 비즈니스 규칙
- API client 함수 전체
- custom hook 전체
- router/navigation 전체
- 실제 사용자 이벤트 대신 내부 함수 호출

## MSW 전략

- 요청은 실제 `fetch`/`axios`/API client 경로를 통과하게 둔다.
- MSW handler는 HTTP method, path, status, response shape를 실제 API와 맞춘다.
- handler는 API 도메인별 파일로 나눈다.
- 테스트 setup에서 `onUnhandledRequest: "error"`를 사용한다.
- `afterEach`에서 handler를 reset한다.
- 개발 모드에서는 `browser.ts` worker를 사용한다.
- 테스트 모드에서는 `server.ts` node server를 사용한다.

## 테스트 데이터 규칙

- `src/mocks/fixtures/`에 API schema/type 기반 fixture factory를 둔다.
- fixture는 최소 기본값만 포함한다.
- 화면별 필요한 값은 override로 전달한다.
- edge case fixture를 명시적으로 둔다.
- 긴 텍스트, 빈 배열, null, 권한 없음, 서버 오류, 지연 응답을 최소 세트로 관리한다.
- API 계약 변경 시 fixture와 handler를 같은 PR에서 수정한다.

## 권장 폴더 구조

```text
frontend/
  src/
    api/
    features/
    components/
    mocks/
      handlers/
        user.handlers.ts
        order.handlers.ts
      fixtures/
        user.fixture.ts
        order.fixture.ts
      browser.ts
      server.ts
    test/
      factories/
      setup.ts
```

## MSW 예시

```ts
// src/mocks/fixtures/user.fixture.ts
export function userFixture(overrides = {}) {
  return {
    id: "user_1",
    name: "홍길동",
    role: "admin",
    ...overrides,
  };
}
```

```ts
// src/mocks/handlers/user.handlers.ts
import { http, HttpResponse } from "msw";
import { userFixture } from "../fixtures/user.fixture";

export const userHandlers = [
  http.get("/api/users/:id", () => {
    return HttpResponse.json(userFixture());
  }),
];
```

```ts
// src/mocks/server.ts
import { setupServer } from "msw/node";
import { userHandlers } from "./handlers/user.handlers";

export const server = setupServer(...userHandlers);
```

```ts
// src/test/setup.ts
import { server } from "../mocks/server";

beforeAll(() => server.listen({ onUnhandledRequest: "error" }));
afterEach(() => server.resetHandlers());
afterAll(() => server.close());
```

```ts
// test-specific override
server.use(
  http.get("/api/users/:id", () => {
    return HttpResponse.json({ message: "Forbidden" }, { status: 403 });
  })
);
```

## 리뷰 체크리스트

- [ ] API client 함수를 직접 Mock하지 않았는가?
- [ ] MSW handler가 실제 method/path/status/response shape와 일치하는가?
- [ ] unhandled request가 error로 처리되는가?
- [ ] 테스트마다 handler가 reset되는가?
- [ ] fixture가 API 계약과 일치하는가?
- [ ] 컴포넌트/상태관리/form validation/비즈니스 규칙을 Mock하지 않았는가?
- [ ] 빈 데이터, 에러, 권한 없음, 지연 응답 등 필요한 edge case만 포함했는가?
