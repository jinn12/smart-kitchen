CREATE TABLE household (
                           id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                           name        VARCHAR(50) NOT NULL,
                           created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE app_user (
                          id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                          household_id  BIGINT NOT NULL REFERENCES household(id),
                          email         VARCHAR(255) NOT NULL UNIQUE,
                          nickname      VARCHAR(30),
    -- 인증 컬럼(password_hash / provider 등)은 로그인 방식 확정 후 추가 (미정)
                          created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE ingredient (
                            id                        BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                            household_id              BIGINT REFERENCES household(id),  -- NULL = 시스템 마스터 (D-005)
                            name                      VARCHAR(50) NOT NULL,
                            category                  VARCHAR(30) NOT NULL,
                            unit_type                 VARCHAR(10) NOT NULL CHECK (unit_type IN ('COUNT','WEIGHT','VOLUME')),  -- D-004
                            package_name              VARCHAR(20),                      -- 예: "모" (표시 전용)
                            package_size              NUMERIC(10,2),                    -- 예: 300 (g)
                            default_storage           VARCHAR(10) NOT NULL CHECK (default_storage IN ('FRIDGE','FREEZER','PANTRY')),
                            default_shelf_life_days   INT,                              -- D-005, D-007
                            is_trackable              BOOLEAN NOT NULL DEFAULT true,    -- D-004
                            is_custom                 BOOLEAN NOT NULL DEFAULT false,
                            created_at                TIMESTAMPTZ NOT NULL DEFAULT now()
);
-- 마스터/커스텀 각각의 이름 중복 방지 (부분 유니크 인덱스)
CREATE UNIQUE INDEX ux_ingredient_master_name ON ingredient(name) WHERE household_id IS NULL;
CREATE UNIQUE INDEX ux_ingredient_custom_name ON ingredient(household_id, name) WHERE household_id IS NOT NULL;

CREATE TABLE inventory (
                           id                 BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                           household_id       BIGINT NOT NULL REFERENCES household(id),
                           ingredient_id      BIGINT NOT NULL REFERENCES ingredient(id),
                           quantity           NUMERIC(10,2) NOT NULL DEFAULT 0 CHECK (quantity >= 0),          -- 실물 보유량 = 배치 합계
                           reserved_quantity  NUMERIC(10,2) NOT NULL DEFAULT 0 CHECK (reserved_quantity >= 0), -- D-002
                           storage_location   VARCHAR(10) NOT NULL CHECK (storage_location IN ('FRIDGE','FREEZER','PANTRY')),
                           UNIQUE (household_id, ingredient_id)
);

CREATE TABLE inventory_item (  -- 배치 (D-003)
                                id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                                inventory_id  BIGINT NOT NULL REFERENCES inventory(id),
                                quantity      NUMERIC(10,2) NOT NULL CHECK (quantity >= 0),
                                expiry_date   DATE,                                  -- NULL 허용, FEFO 마지막 순서
                                purchased_at  DATE NOT NULL DEFAULT CURRENT_DATE,
                                created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);
-- FEFO 차감 순서 조회용 (R-2)
CREATE INDEX ix_inventory_item_fefo ON inventory_item(inventory_id, expiry_date NULLS LAST, purchased_at);
-- 임박 배치 집계용 (R-5)
CREATE INDEX ix_inventory_item_expiry ON inventory_item(expiry_date) WHERE expiry_date IS NOT NULL;

CREATE TABLE recipe (
                        id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                        household_id  BIGINT NOT NULL REFERENCES household(id),
                        name          VARCHAR(50) NOT NULL,
                        servings      INT NOT NULL DEFAULT 1 CHECK (servings > 0),  -- 기준 인분 (D-015)
                        created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE recipe_ingredient (
                                   id             BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                                   recipe_id      BIGINT NOT NULL REFERENCES recipe(id) ON DELETE CASCADE,
                                   ingredient_id  BIGINT NOT NULL REFERENCES ingredient(id),
                                   quantity       NUMERIC(10,2) NOT NULL CHECK (quantity > 0),  -- 단위는 ingredient 기본 단위 고정 (D-004)
                                   UNIQUE (recipe_id, ingredient_id)
);

CREATE TABLE meal_plan (
                           id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                           household_id  BIGINT NOT NULL REFERENCES household(id),
                           recipe_id     BIGINT NOT NULL REFERENCES recipe(id),
                           plan_date     DATE NOT NULL,
                           meal_type     VARCHAR(10) NOT NULL CHECK (meal_type IN ('BREAKFAST','LUNCH','DINNER')),  -- D-012
                           servings      INT NOT NULL CHECK (servings > 0),  -- 선택 인분, 기본값은 recipe.servings (D-015)
                           status        VARCHAR(10) NOT NULL DEFAULT 'PLANNED' CHECK (status IN ('PLANNED','CONFIRMED','CANCELED')),
                           created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX ix_meal_plan_calendar ON meal_plan(household_id, plan_date);       -- 주간 캘린더 조회
CREATE INDEX ix_meal_plan_batch ON meal_plan(status, plan_date);                -- 확정 배치 조회 (R-6)

CREATE TABLE meal_plan_item (  -- 계획별 예약 스냅샷 (R-1, D-010)
                                id             BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                                meal_plan_id   BIGINT NOT NULL REFERENCES meal_plan(id) ON DELETE CASCADE,
                                ingredient_id  BIGINT NOT NULL REFERENCES ingredient(id),
                                required_qty   NUMERIC(10,2) NOT NULL CHECK (required_qty > 0),
                                reserved_qty   NUMERIC(10,2) NOT NULL CHECK (reserved_qty >= 0),  -- "있는 만큼 사용" 시 required보다 작을 수 있음
                                UNIQUE (meal_plan_id, ingredient_id)
);

CREATE TABLE shopping_list (
                               id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                               household_id  BIGINT NOT NULL UNIQUE REFERENCES household(id)  -- 가구당 1개 (D-009)
);

CREATE TABLE shopping_list_item (
                                    id             BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                                    list_id        BIGINT NOT NULL REFERENCES shopping_list(id),
                                    ingredient_id  BIGINT NOT NULL REFERENCES ingredient(id),
                                    quantity       NUMERIC(10,2) NOT NULL CHECK (quantity > 0),
                                    is_checked     BOOLEAN NOT NULL DEFAULT false,
                                    source         VARCHAR(10) NOT NULL DEFAULT 'MANUAL' CHECK (source IN ('MANUAL','SHORTAGE')),  -- D-010
                                    created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
                                    UNIQUE (list_id, ingredient_id)  -- 같은 식재료는 수량 합산으로 병합
);

CREATE TABLE inventory_history (
                                   id             BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                                   household_id   BIGINT NOT NULL REFERENCES household(id),
                                   ingredient_id  BIGINT NOT NULL REFERENCES ingredient(id),
                                   type           VARCHAR(10) NOT NULL CHECK (type IN ('PURCHASE','CONSUME','DISPOSE','ADJUST')),
                                   quantity       NUMERIC(10,2) NOT NULL,   -- 증가 +, 감소 -
                                   ref_type       VARCHAR(20),              -- 예: MEAL_PLAN, SHOPPING_LIST
                                   ref_id         BIGINT,
                                   created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX ix_history_lookup ON inventory_history(household_id, ingredient_id, created_at DESC);
