# API 명세

- 시작일: 2026-08-03 / 기능 구현 시점마다 엔드포인트 단위(API-번호)로 추가한다.
- 공통: base path `/api`, 응답은 JSON. 인증 필요 API는 `Authorization: Bearer {JWT}` (D-018).

## 공통 오류 응답 (D-028, 2026-08-20 확정)

모든 오류는 아래 형태로 응답한다. 앱은 `status`로 분기하고 `message`를 사용자에게 노출할 수 있다.

```json
{ "timestamp": "2026-08-20T05:58:46.543Z", "status": 409, "error": "Conflict",
  "message": "이미 가입된 이메일입니다", "path": "/api/auth/signup" }
```

| 상태 | 발생 조건 | message |
| :---- | :---- | :---- |
| 400 | 도메인 검증 실패 | 서비스가 정한 한국어 사유 |
| 400 | JSON 파싱·타입 오류 | 요청 형식이 올바르지 않습니다 |
| 401 | 토큰 없음·위조·만료 | 인증이 필요합니다 |
| 401 | 로그인 실패 | 이메일 또는 비밀번호가 올바르지 않습니다 |
| 403 | 인증됐으나 권한 부족 | 접근 권한이 없습니다 (현재 미사용) |
| 404 | 없는 경로 | 요청한 경로를 찾을 수 없습니다 |
| 404 | 없는 리소스·타 household (D-022) | 서비스가 정한 한국어 사유 |
| 405 | 미지원 메서드 | 지원하지 않는 요청 방식입니다 |
| 500 | 그 외 모든 예외 | 서버 오류가 발생했습니다 — **내부 정보 미노출** |

인증 없는 요청은 경로 존재 여부와 무관하게 401이 먼저다 (D-022와 같은 비노출 원칙).

## 전체 목록

번호는 도메인별 10단위. "예정" 항목은 목록 스케치이며 상세 명세는 구현 직전에 확정한다.

| ID | Method / Path | 설명 | 상태 |
| :---- | :---- | :---- | :---- |
| API-01 | POST /api/auth/signup | 회원가입 + Household 자동 생성 (D-006) | 완료 (2026-08-19) |
| API-02 | POST /api/auth/login | 로그인, JWT 발급 (D-018) | 완료 (2026-08-19) |
| API-03 | GET /api/me | 내 정보 조회 (이메일·닉네임) — 앱 계정 표시의 진실원 (현재는 로그인 시점 로컬 캐시) | 예정 |
| API-10 | GET /api/ingredients | 식재료 검색 (마스터+내 커스텀, keyword·category 필터) | 완료 (2026-08-20) |
| API-11 | POST /api/ingredients | 커스텀 식재료 등록 (D-005) | 완료 (2026-08-20) |
| API-20 | GET /api/inventories | 재고 목록 (보관 장소 필터, 가용 수량) — S-11 | 완료 (2026-08-20) |
| API-21 | POST /api/inventories/items | 재고 일괄 등록 (배치 생성) — S-13 | 완료 (2026-08-20) |
| API-22 | GET /api/inventories/{ingredientId} | 재고 상세 (배치 목록·기록) — S-12 | 완료 (2026-08-20) |
| API-23 | PATCH /api/inventories/items/{id} | 배치 수정·소진·폐기 | 완료 (2026-08-20) |
| API-24 | GET /api/inventories/expiring | 임박·만료 목록 (D-013) | 완료 (2026-08-20) |
| API-25 | PATCH /api/inventories/{ingredientId} | 재고 보관 장소 변경 | 완료 (2026-08-20) |
| API-30 | GET /api/recipes | 요리 목록 — S-21 | 완료 (2026-08-20) |
| API-31 | POST /api/recipes | 요리 등록 (재료+기준 인분, D-015) — S-23 | 완료 (2026-08-20) |
| API-32 | GET /api/recipes/{id} | 요리 상세 (재료별 가용 여부) — S-22 | 완료 (2026-08-20) |
| API-33 | GET /api/recipe-masters | 공공 레시피 검색 (페이징) | 완료 (2026-08-20) |
| API-34 | GET /api/recipe-masters/{id} | 마스터 상세 = 재료 매핑 확인 화면 | 완료 (2026-08-20) |
| API-40 | GET /api/meal-plans | 주간 식탁 조회 — S-31 | 완료 (2026-08-20) |
| API-41 | POST /api/meal-plans/preview | 등록 전 부족 재료 미리보기 (D-010) — S-32 | 완료 (2026-08-20) |
| API-42 | POST /api/meal-plans | 계획 등록 (재고 예약, R-1) | 완료 (2026-08-20) |
| API-43 | DELETE /api/meal-plans/{id} | 계획 취소 (예약 해제) — S-33 | 완료 (2026-08-20) |
| API-50 | GET /api/shopping-list | 장보기 목록 — S-41 | 완료 (2026-08-20) |
| API-51 | POST /api/shopping-list/items | 항목 추가 (수동) | 완료 (2026-08-20) |
| API-52 | PATCH /api/shopping-list/items/{id} | 체크/수량 수정 | 완료 (2026-08-20) |
| API-53 | POST /api/shopping-list/complete | 구매 완료 → 배치 생성·재고 반영 — S-42 | 완료 (2026-08-20) |
| API-54 | DELETE /api/shopping-list/items/{id} | 장보기 항목 삭제 | 완료 (2026-08-20) |

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
    "unitType": "WEIGHT", "defaultStorage": "FRIDGE", "defaultShelfLifeDays": 10,
    "isTrackable": true, "isCustom": false } ]
```

- isCustom: household_id가 NULL이 아니면 true (D-005)
- defaultStorage(2026-08-20 추가): 신규 재고 등록 시 초기 보관 장소. S-13에서 "냉장에 보관됩니다 · 유통기한은 구매일+10일" 미리보기 용도 — 이미 재고가 있으면 사용자가 바꾼 보관 장소가 유지되므로(D-025) 실제 결과와 다를 수 있다
- category 값은 조회에서는 검증하지 않는다(13종 외 값 → 빈 배열). 검증은 등록(API-11)에서 400으로 수행 — "조회는 관대하게, 쓰기는 엄격하게" (D-019와 동일 원칙)
- 오류: 401 토큰 없음·위조·만료 (공통 오류 응답 참조, D-028)

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
- 401 — 토큰 없음·위조·만료 (D-028)

비고: 마스터와 같은 이름은 허용 — 자기 집 버전을 만들 수 있어야 하므로 (D-005). 중복 기준은 ERD의 부분 유니크 인덱스 ux_ingredient_custom_name과 일치(서비스 검사 + DB 제약 이중 방어).

## API-20. 재고 목록

`GET /api/inventories` — 인증 필요

쿼리 파라미터: `storageLocation`(FRIDGE|FREEZER|PANTRY, 선택). 없으면 전체. ingredient 단위로 배치를 합산, 재료명 오름차순.

응답 200:
```json
[ { "ingredientId": 91, "name": "삼겹살", "category": "정육/가공육/달걀",
    "unitType": "WEIGHT", "storageLocation": "FRIDGE",
    "totalQuantity": 500.00, "reservedQuantity": 0.00, "availableQuantity": 500.00,
    "nearestExpiryDate": "2026-08-23", "dday": 3, "expiryStatus": "EXPIRING" } ]
```

- availableQuantity = totalQuantity − reservedQuantity (R-1). 예약은 API-42에서 발생
- nearestExpiryDate: 잔량 있는 배치 중 가장 이른 유통기한 (없으면 null)
- dday: 당일 0, 경과 시 음수. expiryStatus: EXPIRED(dday<0) / EXPIRING(0≤dday≤3, D-020) / NORMAL / NONE

## API-21. 재고 일괄 등록

`POST /api/inventories/items` — 인증 필요

요청(배열):
```json
[ { "ingredientId": 171, "quantity": 300 },
  { "ingredientId": 186, "quantity": 1000, "purchasedAt": "2026-08-18" },
  { "ingredientId": 91, "quantity": 500, "expiryDate": "2026-08-23" } ]
```

- purchasedAt 생략 시 오늘. expiryDate 생략 시 purchasedAt + default_shelf_life_days (D-017), 기간 없는 재료는 NULL(FEFO 마지막 순서, R-2)
- storageLocation은 받지 않는다 — 신규 재고는 ingredient.defaultStorage로 초기화, 기존 재고는 사용자가 바꾼 값 유지
- 같은 재료 반복 시 배치 다건 생성·수량 합산. 등록 건마다 InventoryHistory(PURCHASE) 기록

응답 201: 영향받은 재고 요약 (API-20 항목과 동일 형태)

오류:
- 400 — 빈 배열 / quantity ≤ 0 / is_trackable=false 재료 (R-4) / 사용할 수 없는 ingredientId (없는 id·타 household 커스텀을 구분 없이 동일 응답 — 존재 여부 비노출, D-006)
- 401 — 토큰 없음·위조·만료 (D-028)

비고: 한 항목이라도 실패하면 전체 미저장(원자성).

## API-22. 재고 상세

`GET /api/inventories/{ingredientId}` — 인증 필요

응답 200:
```json
{ "summary": { "...": "API-20 항목과 동일" },
  "batches": [ { "id": 1, "quantity": 300.00, "purchasedAt": "2026-08-20",
                 "expiryDate": "2026-08-30", "dday": 10 } ],
  "history": [ { "id": 12, "type": "CONSUME", "quantity": -100.00,
                 "refType": null, "refId": null, "createdAt": "2026-08-20T00:53:11Z" } ] }
```

- batches: 잔량 > 0인 배치만 (D-021). FEFO 순 — 유통기한 오름차순, NULL 마지막, 동률은 구매일 (R-2)
- history: 최근 20건 최신순. quantity는 증감 부호(델타)
- 404: 재고 없음·없는 재료·타 household 구분 없이 동일 (D-022)

## API-23. 배치 수정·소진·폐기

`PATCH /api/inventories/items/{id}` — 인증 필요

요청: `{ "action": "ADJUST" | "CONSUME" | "DISCARD", "quantity": 100 }`

- ADJUST: 잔량을 quantity로 변경(증가·감소·0 허용, quantity 필수) / CONSUME·DISCARD: 잔량 0 (quantity 불필요)
- 배치 행은 지우지 않는다 — 이력·FEFO 근거 보존 (D-021). 처리 후 inventory.quantity 재계산
- 이력: ADJUST→ADJUST / CONSUME→CONSUME / DISCARD→DISPOSE, quantity는 델타

응답 200: 처리 후 재고 요약 (API-20 항목 형태)

오류: 400 quantity 음수·ADJUST에 누락 / 404 없는·타 household 배치 (D-022)

## API-24. 임박·만료 목록

`GET /api/inventories/expiring` — 인증 필요

expiryStatus가 EXPIRED·EXPIRING인 재고만, dday 오름차순(만료가 위), 동률은 재료명. 매일 09:00 요약 푸시(D-013, R-5)의 데이터원.

응답 200: API-20 항목 배열

## API-25. 재고 보관 장소 변경

`PATCH /api/inventories/{ingredientId}` — 인증 필요

요청: `{ "storageLocation": "FREEZER" }` — storage_location은 inventory 행 속성이라 해당 재료의 배치 전체가 함께 이동

응답 200: 변경 후 재고 요약 / 404: 재고 없음·타 household (D-022)

## API-33. 공공 레시피 검색

`GET /api/recipe-masters` — 인증 필요, household 스코프 없음(전원 공통 데이터)

쿼리: `keyword`(이름 부분일치) / `category`(밥·국&찌개·반찬·일품·후식·기타) / `page`(0부터, 기본 0) / `size`(기본 20, 1~100 절삭)

응답 200:
```json
{ "totalCount": 1152, "page": 0, "size": 20,
  "items": [ { "id": 7, "name": "된장국", "category": "국&찌개",
               "cookWay": "끓이기", "imageUrl": "...", "kcal1p": 55.0 } ] }
```

오류: 400 page < 0

## API-34. 마스터 상세 (재료 매핑 확인 화면)

`GET /api/recipe-masters/{id}` — 인증 필요

응답 200: 기본 정보 + servings(항상 1, D-015) + ingredients:
```json
[ { "rawText": "두부 20g(2×2×2cm)", "parsedName": "두부", "parsedQty": 20.0,
    "parsedUnit": "g", "matchedIngredient": null } ]
```

- matchedIngredient가 null인 항목이 사용자 지정 대상 (D-007 자동 확정 금지)
- 404: D-022

## API-30. 내 요리 목록

`GET /api/recipes` — household 스코프, 이름 오름차순

응답 200: `[ { id, name, servings, source, ingredientCount, cookableNow } ]`

- cookableNow: 모든 재료의 가용 수량 ≥ **레시피 기준 분량**(quantity 그대로, D-024). is_trackable=false 재료는 판단 제외 (R-4)

## API-31. 내 요리 등록

`POST /api/recipes` — 인증 필요

- MANUAL: `{ "source":"MANUAL", "name":..., "servings":n, "ingredients":[{ingredientId,quantity}] }`
- MASTER 복제: `{ "source":"MASTER", "recipeMasterId":..., "servings":n, "ingredients":[...] }` — name은 마스터에서 복사, servings 생략 시 1(D-015). ingredients는 매핑 확인 화면에서 사용자가 확정한 최종 목록

오류 400: name 누락·공백(MANUAL) / ingredients 빈 배열 / quantity ≤ 0 / servings < 1 / 같은 ingredientId 중복 / 사용할 수 없는 ingredientId (D-006·D-022) / MASTER인데 recipeMasterId 누락·미존재

비고: "같은 ingredientId 중복 400"은 마스터 복제에서 실제로 발생한다(예: "표고버섯 20g"과 "표고버섯 기둥"이 같은 재료로 매핑). 앱(매핑 확인 화면)이 저장 전에 선제 안내·차단한다 (D-030).

응답 201: API-32와 동일한 상세

## API-32. 내 요리 상세

`GET /api/recipes/{id}` — 404는 D-022

응답 200: 기본 정보 + cookableNow + ingredients: `[ { ingredientId, name, quantity, unitType, availableQuantity, sufficient } ]` — sufficient는 is_trackable=false면 null(판단 제외)

## API-41. 계획 등록 전 미리보기

`POST /api/meal-plans/preview` — 조회 전용, 아무것도 변경하지 않음 (S-32, D-010)

요청: `{ "recipeId": 5, "servings": 2 }` — servings 생략 시 recipe.servings

응답 200: 요약(shortageCount) + ingredients: `[ { ingredientId, name, unitType, requiredQuantity, availableQuantity, shortageQuantity, trackable } ]`

- requiredQuantity = recipe_ingredient.quantity × (servings ÷ recipe.servings), 소수 2자리 (D-015)
- trackable=false 재료는 계량 제외 표시 — shortage 0, shortageCount에 불포함 (R-4)

## API-42. 계획 등록 (재고 예약)

`POST /api/meal-plans`

요청: `{ recipeId, planDate, mealType, servings, addToShoppingIngredientIds: [...] }`

- 재료별 예약량 = **min(필요량, 등록 시점 가용량)** — "있는 만큼 사용"이 기본 (D-010, R-1)
- 예약량은 meal_plan_item에 **스냅샷 저장**, 취소는 이 값으로 원복(재계산 금지)
- addToShoppingIngredientIds에 포함된 재료의 부족량만 장보기에 담는다 — 병합 규칙은 D-025
- inventory 행을 ingredient.id 오름차순 PESSIMISTIC_WRITE 잠금 후 갱신 (D-025)
- status=PLANNED 생성. 날짜 경과 후 확정(FEFO 차감)은 배치 작업(R-6) 회차

오류 400: 과거 planDate / servings < 1 / 사용할 수 없는 recipeId(D-022) / 잘못된 mealType / 재료 없는 요리

응답 201: 계획 상세 (재료별 required·reserved·shortage·addedToShoppingList)

## API-40. 주간 식탁

`GET /api/meal-plans?from=&to=` — from 기본 오늘, to 기본 from+6일

응답 200: `[ { date, meals: [ { id, mealType, recipeName, servings, status } ] } ]`

- 기간 내 모든 날짜 반환(계획 없는 날은 빈 배열). CANCELED 제외 (D-025)
- 끼니 순 정렬은 enum 선언 순 — meal_type이 문자열 컬럼이라 DB 정렬은 알파벳순이므로 서버가 정렬

오류 400: from > to / 기간 31일 초과

## API-43. 계획 취소

`DELETE /api/meal-plans/{id}` — meal_plan_item 스냅샷만큼 reserved_quantity 원복. status=CANCELED로 두고 행은 보존(D-021 원칙). 404는 D-022

오류 400: 이미 취소·확정된 계획 / 응답 200: `{ id, status, releasedIngredientCount }`

## API-50. 장보기 목록

`GET /api/shopping-list` — household당 1개 목록을 get-or-create (D-009 단일 장바구니)

응답 200: `{ id, items: [ { id, ingredientId, name, unitType, quantity, isChecked, source, packageName, packageSize } ] }`

- 정렬: 미체크 먼저, 그 안에서 재료명 오름차순. packageName·packageSize는 "두부 300g(1모)" 표시용 (D-004)

## API-51. 수동 추가

`POST /api/shopping-list/items` — `{ "ingredientId": ..., "quantity": ... }`

- 같은 재료가 있으면 가산 + 체크 해제, source는 기존 값 유지 (D-025 — 계획 유래 경로와 규칙 공유)
- is_trackable=false 재료도 담을 수 있다 (D-017: 장보기에는 수동으로만)

오류 400: quantity ≤ 0 / 사용할 수 없는 ingredientId (D-006·D-022) / 응답 200: 갱신된 목록

## API-52. 체크·수량 수정

`PATCH /api/shopping-list/items/{id}` — `{ "isChecked": bool?, "quantity": n? }` 온 필드만 반영

오류 400 quantity ≤ 0 / 404는 D-022 / 응답 200: 해당 항목

## API-53. 구매 완료 → 재고 반영

`POST /api/shopping-list/complete` — 체크된 항목만, 전체 한 트랜잭션 (순환의 마지막 연결)

- 재고 반영은 API-21과 동일 경로(InventoryService 재사용): 구매일=오늘, 유통기한 자동 계산, PURCHASE 이력, 합산
- is_trackable=false 항목은 재고 반영 없이 목록에서만 제거 (R-4)
- 반영한 체크 항목은 행 삭제 (D-026 — 구매 이력은 inventory_history가 단일 진실), 미체크는 이월

오류 400: 체크 항목 0개 / 응답 200: `{ inventories: [API-20 항목 형태], carriedOverCount }`

## API-54. 항목 삭제

`DELETE /api/shopping-list/items/{id}` — 물리 삭제 (보존 가치 없음, D-026). 404는 D-022

## 배치 작업 (엔드포인트 아님 — API 번호 없음)

| 작업 | cron (Asia/Seoul) | 내용 | 상태 |
| :---- | :---- | :---- | :---- |
| 계획 확정 | 0 10 0 * * * | 날짜 경과 PLANNED → FEFO 차감 확정, CONSUME 이력(ref=MEAL_PLAN). 규칙은 R-6 | 완료 (2026-08-20) |
| 임박 요약 | 0 0 9 * * * | 가구별 임박·만료 집계(API-24 로직 공유) → 발송. 현재는 로그 구현체, FCM은 앱 개발 후 | 완료 (2026-08-20) |

- 멱등: 재실행해도 이중 차감·이중 기록 없음 (검증 완료)
- 배치 로직은 서비스 메서드로 분리되어 있어 스케줄러와 독립적으로 실행·테스트 가능
