# API 명세

- 시작일: 2026-08-03 / 기능 구현 시점마다 엔드포인트 단위(API-번호)로 추가한다.
- 공통: base path `/api`, 응답은 JSON. 인증 필요 API는 `Authorization: Bearer {JWT}` (D-018).

## 전체 목록

번호는 도메인별 10단위. "예정" 항목은 목록 스케치이며 상세 명세는 구현 직전에 확정한다.

| ID | Method / Path | 설명 | 상태 |
| :---- | :---- | :---- | :---- |
| API-01 | POST /api/auth/signup | 회원가입 + Household 자동 생성 (D-006) | 완료 (2026-08-19) |
| API-02 | POST /api/auth/login | 로그인, JWT 발급 (D-018) | 완료 (2026-08-19) |
| API-10 | GET /api/ingredients | 식재료 검색 (마스터+내 커스텀, keyword·category 필터) | 완료 (2026-08-20) |
| API-11 | POST /api/ingredients | 커스텀 식재료 등록 (D-005) | 완료 (2026-08-20) |
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

## API-10. 식재료 검색

`GET /api/ingredients` — 인증 필요

쿼리 파라미터: `keyword`(이름 부분일치, 선택), `category`(13종 중 하나, 선택). 둘 다 없으면 전체, 빈 문자열은 미지정과 동일.

검색 범위: 마스터(household_id IS NULL) + 요청자 household의 커스텀만 (D-006). 이름 오름차순.

응답 200:
```json
[ { "id": 171, "name": "두부(부침용)", "category": "두부/콩/묵",
    "unitType": "WEIGHT", "defaultShelfLifeDays": 10,
    "isTrackable": true, "isCustom": false } ]
```

- isCustom: household_id가 NULL이 아니면 true (D-005)
- category 값은 조회에서는 검증하지 않는다(13종 외 값 → 빈 배열). 검증은 등록(API-11)에서 400으로 수행 — "조회는 관대하게, 쓰기는 엄격하게" (D-019와 동일 원칙)
- 오류: 403 토큰 없음·만료 — 401 통일(AuthenticationEntryPoint)은 전역 예외 처리 정리 시 함께 (추후 과제)

## API-11. 커스텀 식재료 등록

`POST /api/ingredients` — 인증 필요. 요청자의 household 소유로 생성 (D-006)

요청 (필수: name, category, unitType, defaultStorage):
```json
{ "name": "할머니표 된장", "category": "양념/오일", "unitType": "WEIGHT",
  "defaultStorage": "FRIDGE", "packageName": "통", "packageSize": 500,
  "defaultShelfLifeDays": 365, "isTrackable": true }
```

응답 201: API-10과 동일한 단건 형태 (isCustom: true)

오류:
- 400 — name 누락·공백만 / category가 D-017의 13종 외 / isTrackable=false인데 defaultShelfLifeDays 있음 (D-017 시드 규칙) / unitType·defaultStorage 허용값 밖
- 409 — 같은 household에 동일 name(trim 기준) 커스텀이 이미 존재
- 403 — 토큰 없음·만료

비고: 마스터와 같은 이름은 허용 — 자기 집 버전을 만들 수 있어야 하므로 (D-005). 중복 기준은 ERD의 부분 유니크 인덱스 ux_ingredient_custom_name과 일치(서비스 검사 + DB 제약 이중 방어).
