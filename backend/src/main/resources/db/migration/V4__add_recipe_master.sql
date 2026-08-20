-- 요리 도메인 v1: 조리식품 레시피 DB(COOKRCP01) 적재 테이블 (D-014, 외부 API 검토 3절)
-- 실시간 호출이 아닌 배치 적재 방식이며, 재료 자유텍스트는 적재 시점에 선처리해 둔다.

CREATE TABLE recipe_master (  -- COOKRCP01 적재본 (시스템 소유, household 없음)
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    external_seq    VARCHAR(20) NOT NULL UNIQUE,      -- RCP_SEQ, 재적재 시 중복 방지
    name            VARCHAR(100) NOT NULL,            -- RCP_NM
    category        VARCHAR(20) NOT NULL,             -- RCP_PAT2 (밥/국&찌개/반찬/일품/후식)
    cook_way        VARCHAR(20),                      -- RCP_WAY2 (굽기/끓이기/찌기/기타)
    weight_1p       NUMERIC(10,2),                    -- INFO_WGT, 1인분 중량(g). 빈 값이 많아 NULL 허용
    kcal_1p         NUMERIC(10,2),                    -- INFO_ENG
    carb_1p         NUMERIC(10,2),                    -- INFO_CAR
    protein_1p      NUMERIC(10,2),                    -- INFO_PRO
    fat_1p          NUMERIC(10,2),                    -- INFO_FAT
    natrium_1p      NUMERIC(10,2),                    -- INFO_NA
    image_url       VARCHAR(255),                     -- ATT_FILE_NO_MAIN
    raw_parts_text  TEXT NOT NULL,                    -- RCP_PARTS_DTLS 원문. 파싱 규칙 개선 시 재파싱용
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX ix_recipe_master_name ON recipe_master(name);          -- 이름 검색 (S-21)
CREATE INDEX ix_recipe_master_category ON recipe_master(category);  -- 분류 브라우징

CREATE TABLE recipe_master_ingredient (  -- RCP_PARTS_DTLS 파싱 결과 (배치 선처리)
    id                     BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    recipe_master_id       BIGINT NOT NULL REFERENCES recipe_master(id) ON DELETE CASCADE,
    raw_text               VARCHAR(100) NOT NULL,             -- 항목 원문. 예: "연두부 75g(3/4모)"
    parsed_name            VARCHAR(50) NOT NULL,              -- 파싱한 재료명. 예: "연두부"
    parsed_qty             NUMERIC(10,2),                     -- "약간"처럼 수량이 없으면 NULL
    parsed_unit            VARCHAR(10),                       -- g/ml/개/큰술 등. 불명이면 NULL
    matched_ingredient_id  BIGINT REFERENCES ingredient(id),  -- 매핑 실패분은 NULL, 사용자 검증에서 지정 (D-007)
    created_at             TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX ix_recipe_master_ingredient_recipe ON recipe_master_ingredient(recipe_master_id);
-- 매핑 실패분 재처리·마스터 확장 대상 조회용
CREATE INDEX ix_recipe_master_ingredient_unmatched ON recipe_master_ingredient(parsed_name)
    WHERE matched_ingredient_id IS NULL;

-- 기존 recipe: 직접 입력분과 마스터 복제분을 구분한다
ALTER TABLE recipe ADD COLUMN source            VARCHAR(10) NOT NULL DEFAULT 'MANUAL'
    CHECK (source IN ('MANUAL','MASTER'));
ALTER TABLE recipe ADD COLUMN recipe_master_id  BIGINT REFERENCES recipe_master(id);
-- MASTER에서 복제한 요리는 원본을 반드시 가리킨다
ALTER TABLE recipe ADD CONSTRAINT ck_recipe_master_ref
    CHECK (source = 'MANUAL' OR recipe_master_id IS NOT NULL);
