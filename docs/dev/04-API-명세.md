# API 명세

- 시작일: 2026-08-03 / 기능 구현 시점마다 엔드포인트 단위(API-번호)로 추가한다.
- 공통: base path `/api`, 응답은 JSON. 인증 필요 API는 `Authorization: Bearer {JWT}` (D-018).

## 전체 목록

번호는 도메인별 10단위. "예정" 항목은 목록 스케치이며 상세 명세는 구현 직전에 확정한다.

| ID | Method / Path | 설명 | 상태 |
| :---- | :---- | :---- | :---- |
| API-01 | POST /api/auth/signup | 회원가입 + Household 자동 생성 (D-006) | 완료 (2026-08-19) |
| API-02 | POST /api/auth/login | 로그인, JWT 발급 (D-018) | 완료 (2026-08-19) |
| API-10 | GET /api/ingredients | 식재료 검색 (마스터+내 커스텀, keyword·category 필터) | 예정 |
| API-11 | POST /api/ingredients | 커스텀 식재료 등록 (D-005) | 예정 |
| API-20 | GET /api/inventories | 재고 목록 (보관 장소 필터, 가용 수량) — S-11 | 예정 |
| API-21 | POST /api/inventories/items | 재고 일괄 등록 (배치 생성) — S-13 | 예정 |
| API-22 | GET /api/inventories/{ingredientId} | 재고 상세 (배치 목록·기록) — S-12 | 예정 |
| API-23 | PATCH /api/inventories/items/{id} | 배치 수정·소진·폐기 | 예정 |
| API-24 | GET /api/inventories/expiring | 임박·만료 목록 (D-013) | 예정 |
| API-30 | GET /api/recipes | 요리 목록 — S-21 | 예정 |
| API-31 | POST /api/recipes | 요리 등록 (재료+기준 인분, D-015) — S-23 | 예정 |
| API-32 | GET /api/recipes/{id} | 요리 상세 (재료별 가용 여부) — S-22 | 예정 |
| API-40 | GET /api/meal-plans | 주간 식탁 조회 — S-31 | 예정 |
| API-41 | POST /api/meal-plans/preview | 등록 전 부족 재료 미리보기 (D-010) — S-32 | 예정 |
| API-42 | POST /api/meal-plans | 계획 등록 (재고 예약, R-1) | 예정 |
| API-43 | DELETE /api/meal-plans/{id} | 계획 취소 (예약 해제) — S-33 | 예정 |
| API-50 | GET /api/shopping-list | 장보기 목록 — S-41 | 예정 |
| API-51 | POST /api/shopping-list/items | 항목 추가 (수동) | 예정 |
| API-52 | PATCH /api/shopping-list/items/{id} | 체크/수량 수정 | 예정 |
| API-53 | POST /api/shopping-list/complete | 구매 완료 → 배치 생성·재고 반영 — S-42 | 예정 |

## API-01. 회원가입

`POST /api/auth/signup`

요청:
```json
{ "email": "jinny@example.com", "password": "********", "nickname": "유진" }
```

처리: 이메일 중복 검사 → BCrypt 해시 → Household 생성 → User 생성(household 연결)

응답 201:
```json
{ "userId": 1, "email": "jinny@example.com", "nickname": "유진" }
```

오류: 409 이메일 중복, 400 형식 오류(이메일 형식·비밀번호 8자 이상)

## API-02. 로그인

`POST /api/auth/login`

요청:
```json
{ "email": "jinny@example.com", "password": "********" }
```

응답 200:
```json
{ "accessToken": "eyJhbGciOi...", "nickname": "유진" }
```

오류: 401 이메일 또는 비밀번호 불일치 (어느 쪽이 틀렸는지는 알려주지 않음 — 보안 관례)

비고: 토큰 유효기간 24시간(로컬 설정값). 짧은 만료 + 리프레시 토큰은 출시 전 재검토.
