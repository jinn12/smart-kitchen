# API 명세

- 시작일: 2026-08-03 / 기능 구현 시점마다 엔드포인트 단위(API-번호)로 추가한다.
- 공통: base path `/api`, 응답은 JSON. 인증 필요 API는 `Authorization: Bearer {JWT}` (D-018).

## 목록

| ID | Method / Path | 설명 | 인증 | 상태 |
| :---- | :---- | :---- | :---- | :---- |
| API-01 | POST /api/auth/signup | 회원가입 — User 생성 + 개인 Household 자동 생성 (D-006) | 불필요 | 개발 중 |
| API-02 | POST /api/auth/login | 로그인 — JWT 액세스 토큰 발급 (D-018) | 불필요 | 개발 중 |

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
