# Smart Kitchen — Claude Code 지침

냉장고 재고 기준으로 식사 계획→재고→장보기가 순환하는 모바일 앱. 1인 개발, 실제 스토어 출시 목표.

## 언어·소통
- 답변은 한국어로 한다.
- 확정되지 않은 설계는 임의로 정하지 말고 먼저 물어본다.

## 구조
- `backend/` Spring Boot 4 + Kotlin + JPA (IntelliJ) — REST API 서버, 화면 없음
- `app/` Flutter (VS Code) — 모든 UI, backend API 호출
- `docs/` 기획·설계 문서 — **모든 구현의 근거. 코드와 충돌 시 문서가 우선이며, 문서 변경이 필요하면 먼저 제안할 것**

## 문서 체계 (구현 전 반드시 참조)
- `docs/05-ERD.md` — DB 스키마 확정본(v1.0). 스키마의 단일 진실
- `docs/04-도메인-모델-정의서.md` — 엔티티와 핵심 규칙 R-1~R-6 (예약-확정, FEFO, 인분 계산)
- `docs/03-IA-정보구조.md` — 화면 S-01~S-51
- `docs/decisions/decision-log.md` — 결정 D-001~D-016. "D-002대로" 식으로 참조됨
- `docs/dev/02-외부-API-검토.md` — 공공 API 연동 계획 (v1)

## 핵심 규칙
- **스키마 변경은 Flyway 마이그레이션으로만** (`backend/src/main/resources/db/migration/`). JPA ddl-auto는 validate 고정 (D-016)
- 수량 계산은 base_unit으로만 (D-004). 필요량 = 재료량 × (MealPlan.servings ÷ Recipe.servings) (D-015)
- 모든 도메인 조회는 household_id 스코프 (D-006)
- `application-local.yml`은 git 제외 — 절대 커밋하지 않는다. 시크릿을 코드·문서에 넣지 않는다
- MVP 범위(D-009)를 넘는 기능을 임의로 추가하지 않는다
- 커밋 메시지는 한국어, `타입: 내용` 형식 (docs:/feat:/fix:/chore:). 주요 변경은 본문에 D-번호 참조

## 자주 쓰는 명령
- 백엔드 실행: `cd backend && ./gradlew bootRun` (local 프로필, PostgreSQL 필요: localhost:5432/smartkitchen)
- 백엔드 테스트: `cd backend && ./gradlew test`
- 앱 실행: `cd app && flutter run -d chrome`

## 환경 주의
- Windows + 이동식 디스크(E:). 회사 노트북이므로 전역 설정(JAVA_HOME, PATH)을 절대 건드리지 않는다
- JDK는 C:\dev\jdk-21 (Gradle이 알아서 사용), 시스템 java는 1.8이므로 `java` 직접 호출 금지 — 반드시 gradlew 사용
