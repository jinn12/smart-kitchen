# 외부 API 검토 — 공공 식품 데이터

- 작성일: 2026-08-03 / 관련: D-014, D-015 / 상태: 확정

## 결론 요약

- 요리 검색·메뉴 추천(v1)은 **조리식품 레시피 DB**, 식재료 마스터 구축은 **식품영양성분DB**를 사용한다. 둘 다 무료 공공 API.
- 실시간 호출이 아닌 **배치 적재(import)** 방식 — 자체 테이블에 넣고 검색한다. 이유: 응답 속도, 공공 API 장애 격리, 재료 텍스트 파싱을 배치에서 선처리.

## 1. 조리식품 레시피 DB (COOKRCP01) — v1 요리 검색·추천용

- 출처: [공공데이터포털 15060073](https://www.data.go.kr/data/15060073/openapi.do) / 약 1,100건 / **1인분 기준** (D-015의 기준 인분=1로 적재)
- 샘플: `http://openapi.foodsafetykorea.go.kr/api/sample/COOKRCP01/json/1/3` (인증키 불필요)

| 필드 | 내용 | 용도 |
| :---- | :---- | :---- |
| RCP_SEQ | 고유번호 | 외부 참조 ID (중복 방지) |
| RCP_NM | 메뉴명 | 요리 이름 |
| RCP_PAT2 | 분류 (밥/국&찌개/반찬/일품/후식) | 검색 브라우징 |
| RCP_WAY2 | 조리방법 | 검색 필터 (선택) |
| **RCP_PARTS_DTLS** | **재료 목록 (자유 텍스트)** | **파싱 → 마스터 매핑 제안 → 사용자 검증 (D-007 패턴)** |
| INFO_WGT / INFO_ENG·CAR·PRO·FAT·NA | 1인분 중량·영양 | 저장만, 영양 기능(확장) 대비 |
| ATT_FILE_NO_MAIN | 사진 URL | 검색 썸네일 |
| MANUAL01~20 | 조리 단계 | **미사용** (D-009 조리법 제외) |

## 2. 식품영양성분DB (15127578) — 마스터 구축 보조 (1회성)

- 출처: [공공데이터포털 15127578](https://www.data.go.kr/data/15127578/openapi.do) / 식품(재료) 단위, 영양 컬럼 190여 개

| 필드 | 용도 |
| :---- | :---- |
| FOOD_CD / FOOD_NM_KR | 마스터 300~500건 이름 후보 |
| FOOD_CAT1_NM / FOOD_REF_NM | **ingredient.category 분류 체계 유도** (미결정 항목 해소) |
| SERVING_SIZE + 주요 영양 6개 (AMT_NUM1~6) | 확장 대비. 나머지 컬럼은 버림 |

## 3. 적재 시 추가 테이블 (v1 시점, ERD에 반영 예정)

```
recipe_master             -- COOKRCP01 적재본 (시스템 소유)
  external_seq UNIQUE, name, category, cook_way,
  kcal_1p 등 영양 5종, image_url, raw_parts_text

recipe_master_ingredient  -- 재료 파싱 결과 (배치 선처리)
  recipe_master_id, raw_text, parsed_qty, parsed_unit,
  matched_ingredient_id NULL 허용  -- 매핑 실패분은 사용자 검증에서 지정
```

기존 `recipe`에는 `source`(MANUAL/MASTER), `recipe_master_id`가 추가된다.

## 4. 사용자 흐름 (v1)

요리 등록 → [직접 입력] 또는 [검색] → 분류 탐색/이름 검색(자체 DB) → 선택 → **재료 매핑 확인 화면**(매핑 실패분만 지정) → 기준 인분 확인 → 내 요리로 저장. 검색 실패 시 직접 입력으로 폴백.

## 리스크

- 레시피 1,100건은 전 메뉴 커버가 아님 → 직접 입력 폴백이 기본 동선 (커스텀과 동일 구조라 추가 비용 없음)
- 재료 파싱 정확도 → 배치 선처리 + 사용자 검증으로 흡수. 자동 확정 금지 원칙(D-007) 준수
- 인증키 발급은 개발 시점에 (공공데이터포털 활용신청, 즉시 발급)
