# 학습 노트 — 기능 API 패턴 (조회·등록)

- 작성일: 2026-08-20 / API-10(검색)·API-11(등록) 구현을 정리. 앞으로 만들 API-20~53이 전부 이 두 패턴의 변주다.

## 전체 흐름 — 요청 한 번의 일생

```
앱 → [JwtAuthFilter] 토큰 검증, userId 기록
   → [SecurityConfig] 통행 판정 (인증 필요 여부)
   → [Controller] HTTP를 코틀린으로 번역: 파라미터/본문 → DTO, userId 꺼내 Service에 전달
   → [Service]    업무 규칙 전부: household 해석, 검증(400/409), 트랜잭션
   → [Repository] DB 왕래만: 파생 쿼리 또는 @Query(JPQL)
   → PostgreSQL
응답은 역순: 엔티티 → (Service에서) Response DTO → JSON
```

각 층의 책임 한 줄 요약 — **Controller는 얇게(번역만), Service가 두뇌, Repository는 손발.**
"이 검증을 어디 넣지?" 고민되면 답은 거의 항상 Service다.

## 반복되는 패턴 (모든 기능 API에서 다시 쓴다)

**1. userId → household 해석.** 필터가 남긴 건 userId뿐이다. 도메인 데이터의 주인은 household(D-006)이므로
Service 첫 줄에서 해석한다. API-11에서 `householdOf(userId)` 헬퍼로 추출됨 — 새 Service를 만들면 같은 헬퍼를 둘 것.

**2. household 스코프는 쿼리 조건에.** 조회는 `(마스터 OR 내 household)`, 쓰기는 내 household 소유로 생성.
**스코프 누락 = 남의 데이터가 새는 최악의 버그**이므로, 새 API마다 "A/B 두 계정 교차 검증"을 완료 기준에 넣는다 (API-11에서 확립한 관례).

**3. 조회는 관대하게, 쓰기는 엄격하게.** 검색에 이상한 category → 빈 배열(에러 아님). 등록에 이상한 category → 400.
같은 값이라도 읽기와 쓰기의 검증 기준이 다르다.

**4. 검증 실패 = ResponseStatusException 한 문장.** 400(형식·규칙 위반) / 409(중복) / 401·403(인증).
`?: throw`, `if (...) throw` 패턴 — auth부터 ingredient까지 동일.

**5. DTO는 방향별로.** 요청(CreateRequest)과 응답(Response)을 분리하고, 엔티티 → DTO 변환은
확장함수 `Entity.toResponse()`로 모은다. 엔티티를 JSON으로 직접 내보내지 않는다(내부 구조 노출 방지).

**6. Repository 쿼리 2단.** 단순 조건은 파생 쿼리(`existsByHouseholdIdAndName` — 이름이 곧 쿼리),
복잡한 조건(OR, 선택적 파라미터)은 `@Query`(JPQL). MyBatis의 XML SQL에 해당하는 것이 @Query다.

## 유지보수 포인트

- **JPQL의 선택적 파라미터 함정**: `:param IS NULL OR ...`를 PostgreSQL이 타입 추론 못 해 500이 남 →
  `CAST(:param AS String)` 필요. IngredientRepository에 주석 있음. 같은 형태의 검색 쿼리를 만들 때마다 재발 가능.
- **카테고리 13종을 고치려면 세 군데**: decision-log D-017(근거) + IngredientService의 CATEGORIES 상수 + (기존 시드와의 정합).
  상수만 고치면 문서와 어긋난다.
- **중복 방어는 이중**: 서비스의 exists 검사(친절한 409 메시지) + DB 부분 유니크 인덱스(동시 요청 등 최후 방어).
  하나만 있으면 안 되는 이유 — 서비스 검사는 동시성에 뚫릴 수 있고, DB 제약만 있으면 사용자가 500을 본다.
- **에러 응답 통일은 미완**: 인증 실패가 401이 아닌 403으로 나감. 전역 예외 처리기 + AuthenticationEntryPoint 도입 시 일괄 정리 (추후 과제).
- **로컬 DB의 테스트 흔적**: 테스트 계정(userId 4·5)과 커스텀 3건(id 361~363). 배포 전 로컬 데이터 정리 시 함께.

## 새 API를 추가할 때의 체크리스트

1. 04-API-명세.md에 상세 확정(요청/응답/오류) → 2. 기능 패키지에 Repository·Dto·Service·Controller →
3. household 스코프 확인 → 4. 검증 규칙(쓰기면 엄격) → 5. Swagger/curl로 성공·실패·스코프 검증 → 6. 명세 상태 "완료 (날짜)" → 7. 커밋(feat)
