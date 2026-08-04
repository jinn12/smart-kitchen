-- 시스템 마스터 식재료 시드 (D-005, D-016)
-- 총 360건. household_id = NULL(마스터), is_custom = false(DEFAULT) 이므로 컬럼 목록에서 생략한다.
--
-- 값 부여 기준
--  * unit_type      : 낱개로 세면 COUNT(개), 무게로 사면 WEIGHT(g), 액체는 VOLUME(ml). 식재료당 1종 고정 (D-004)
--  * package_size   : 해당 unit_type의 base 단위 값. 두부 1모 = 300(g), 달걀 1판 = 30(개)
--                     한국 가정에서 실제로 그 단위로 구매하는 품목만 부여하고, 애매하면 NULL
--  * default_shelf_life_days : 유통기한이 아니라 "구매·등록일 기준 권장 소비 기간" (D-007에서 유통기한을
--                     사진 인식 대상에서 제외하고 이 값으로 날짜를 제안하므로). 일반 보관 조건 기준
--  * is_trackable   : 잔량 정량 관리가 무의미한 품목은 false, 이때 default_shelf_life_days는 NULL (D-004 부가결정)
--                     -> 양념/오일 전체, 커피·차류(원두/믹스/티백), 제빵 보조재
--
-- category는 13종 고정: 채소, 과일, 정육/가공육/달걀, 수산물/건해산, 두부/콩/묵, 우유/유제품,
--                       쌀/잡곡/견과, 면/빵/통조림, 양념/오일, 김치/반찬, 냉동/밀키트, 커피/차/음료, 기타

-- ============================================================
-- 채소 (60)
-- ============================================================
INSERT INTO ingredient (name, category, unit_type, package_name, package_size, default_storage, default_shelf_life_days, is_trackable) VALUES
('양파',         '채소', 'COUNT',  '망',   10,   'PANTRY', 30,  true),
('대파',         '채소', 'COUNT',  '단',   3,    'FRIDGE', 14,  true),
('쪽파',         '채소', 'WEIGHT', '단',   200,  'FRIDGE', 7,   true),
('마늘',         '채소', 'WEIGHT', '봉지', 200,  'FRIDGE', 30,  true),
('다진마늘',     '채소', 'WEIGHT', '팩',   200,  'FRIDGE', 60,  true),
('생강',         '채소', 'WEIGHT', NULL,   NULL, 'FRIDGE', 21,  true),
('감자',         '채소', 'COUNT',  '봉지', 5,    'PANTRY', 30,  true),
('고구마',       '채소', 'COUNT',  '봉지', 5,    'PANTRY', 21,  true),
('당근',         '채소', 'COUNT',  NULL,   NULL, 'FRIDGE', 21,  true),
('무',           '채소', 'COUNT',  NULL,   NULL, 'FRIDGE', 21,  true),
('알타리무',     '채소', 'WEIGHT', '단',   1000, 'FRIDGE', 7,   true),
('배추',         '채소', 'COUNT',  NULL,   NULL, 'FRIDGE', 14,  true),
('알배기배추',   '채소', 'COUNT',  NULL,   NULL, 'FRIDGE', 10,  true),
('양배추',       '채소', 'COUNT',  NULL,   NULL, 'FRIDGE', 21,  true),
('상추',         '채소', 'WEIGHT', '봉지', 150,  'FRIDGE', 5,   true),
('깻잎',         '채소', 'COUNT',  '봉지', 30,   'FRIDGE', 7,   true),
('시금치',       '채소', 'WEIGHT', '단',   200,  'FRIDGE', 5,   true),
('얼갈이배추',   '채소', 'WEIGHT', '단',   800,  'FRIDGE', 5,   true),
('청경채',       '채소', 'WEIGHT', '봉지', 200,  'FRIDGE', 5,   true),
('부추',         '채소', 'WEIGHT', '단',   200,  'FRIDGE', 5,   true),
('미나리',       '채소', 'WEIGHT', '단',   200,  'FRIDGE', 5,   true),
('쑥갓',         '채소', 'WEIGHT', '단',   150,  'FRIDGE', 4,   true),
('근대',         '채소', 'WEIGHT', '단',   300,  'FRIDGE', 5,   true),
('열무',         '채소', 'WEIGHT', '단',   1000, 'FRIDGE', 5,   true),
('오이',         '채소', 'COUNT',  NULL,   NULL, 'FRIDGE', 10,  true),
('애호박',       '채소', 'COUNT',  NULL,   NULL, 'FRIDGE', 10,  true),
('단호박',       '채소', 'COUNT',  NULL,   NULL, 'PANTRY', 30,  true),
('가지',         '채소', 'COUNT',  NULL,   NULL, 'FRIDGE', 7,   true),
('토마토',       '채소', 'COUNT',  NULL,   NULL, 'FRIDGE', 10,  true),
('방울토마토',   '채소', 'WEIGHT', '팩',   500,  'FRIDGE', 10,  true),
('파프리카',     '채소', 'COUNT',  NULL,   NULL, 'FRIDGE', 14,  true),
('피망',         '채소', 'COUNT',  NULL,   NULL, 'FRIDGE', 14,  true),
('청양고추',     '채소', 'WEIGHT', '봉지', 100,  'FRIDGE', 10,  true),
('풋고추',       '채소', 'WEIGHT', '봉지', 200,  'FRIDGE', 10,  true),
('오이고추',     '채소', 'WEIGHT', '봉지', 200,  'FRIDGE', 10,  true),
('브로콜리',     '채소', 'COUNT',  NULL,   NULL, 'FRIDGE', 10,  true),
('콜리플라워',   '채소', 'COUNT',  NULL,   NULL, 'FRIDGE', 10,  true),
('아스파라거스', '채소', 'WEIGHT', '팩',   100,  'FRIDGE', 7,   true),
('셀러리',       '채소', 'WEIGHT', '팩',   300,  'FRIDGE', 10,  true),
('파슬리',       '채소', 'WEIGHT', '팩',   50,   'FRIDGE', 7,   true),
('옥수수',       '채소', 'COUNT',  NULL,   NULL, 'FRIDGE', 7,   true),
('연근',         '채소', 'WEIGHT', '팩',   300,  'FRIDGE', 14,  true),
('우엉',         '채소', 'WEIGHT', '팩',   300,  'FRIDGE', 14,  true),
('도라지',       '채소', 'WEIGHT', '팩',   200,  'FRIDGE', 7,   true),
('더덕',         '채소', 'WEIGHT', '팩',   200,  'FRIDGE', 7,   true),
('표고버섯',     '채소', 'WEIGHT', '팩',   150,  'FRIDGE', 7,   true),
('느타리버섯',   '채소', 'WEIGHT', '팩',   150,  'FRIDGE', 7,   true),
('새송이버섯',   '채소', 'WEIGHT', '팩',   200,  'FRIDGE', 10,  true),
('팽이버섯',     '채소', 'WEIGHT', '봉지', 150,  'FRIDGE', 7,   true),
('양송이버섯',   '채소', 'WEIGHT', '팩',   200,  'FRIDGE', 7,   true),
('목이버섯',     '채소', 'WEIGHT', '봉지', 50,   'PANTRY', 365, true),
('마늘종',       '채소', 'WEIGHT', '봉지', 200,  'FRIDGE', 10,  true),
('양상추',       '채소', 'COUNT',  NULL,   NULL, 'FRIDGE', 7,   true),
('로메인',       '채소', 'WEIGHT', '봉지', 200,  'FRIDGE', 5,   true),
('케일',         '채소', 'WEIGHT', '봉지', 200,  'FRIDGE', 7,   true),
('고사리',       '채소', 'WEIGHT', '팩',   200,  'FRIDGE', 7,   true),
('취나물',       '채소', 'WEIGHT', '팩',   200,  'FRIDGE', 5,   true),
('시래기',       '채소', 'WEIGHT', '팩',   500,  'FRIDGE', 7,   true),
('냉이',         '채소', 'WEIGHT', '팩',   200,  'FRIDGE', 5,   true),
('달래',         '채소', 'WEIGHT', '팩',   100,  'FRIDGE', 5,   true);

-- ============================================================
-- 과일 (30)
-- ============================================================
INSERT INTO ingredient (name, category, unit_type, package_name, package_size, default_storage, default_shelf_life_days, is_trackable) VALUES
('사과',         '과일', 'COUNT',  NULL,   NULL, 'FRIDGE',  21,  true),
('배',           '과일', 'COUNT',  NULL,   NULL, 'FRIDGE',  21,  true),
('단감',         '과일', 'COUNT',  NULL,   NULL, 'FRIDGE',  10,  true),
('귤',           '과일', 'WEIGHT', '박스', 3000, 'FRIDGE',  14,  true),
('오렌지',       '과일', 'COUNT',  NULL,   NULL, 'FRIDGE',  21,  true),
('자몽',         '과일', 'COUNT',  NULL,   NULL, 'FRIDGE',  21,  true),
('레몬',         '과일', 'COUNT',  NULL,   NULL, 'FRIDGE',  21,  true),
('바나나',       '과일', 'COUNT',  '송이', 5,    'PANTRY',  5,   true),
('딸기',         '과일', 'WEIGHT', '팩',   500,  'FRIDGE',  4,   true),
('블루베리',     '과일', 'WEIGHT', '팩',   300,  'FRIDGE',  7,   true),
('포도',         '과일', 'WEIGHT', '송이', 500,  'FRIDGE',  7,   true),
('샤인머스캣',   '과일', 'WEIGHT', '송이', 700,  'FRIDGE',  7,   true),
('수박',         '과일', 'COUNT',  NULL,   NULL, 'FRIDGE',  7,   true),
('참외',         '과일', 'COUNT',  NULL,   NULL, 'FRIDGE',  10,  true),
('멜론',         '과일', 'COUNT',  NULL,   NULL, 'FRIDGE',  10,  true),
('복숭아',       '과일', 'COUNT',  NULL,   NULL, 'FRIDGE',  5,   true),
('자두',         '과일', 'COUNT',  NULL,   NULL, 'FRIDGE',  7,   true),
('체리',         '과일', 'WEIGHT', '팩',   500,  'FRIDGE',  7,   true),
('키위',         '과일', 'COUNT',  NULL,   NULL, 'FRIDGE',  14,  true),
('파인애플',     '과일', 'COUNT',  NULL,   NULL, 'FRIDGE',  7,   true),
('망고',         '과일', 'COUNT',  NULL,   NULL, 'FRIDGE',  7,   true),
('아보카도',     '과일', 'COUNT',  NULL,   NULL, 'FRIDGE',  7,   true),
('무화과',       '과일', 'WEIGHT', '팩',   400,  'FRIDGE',  4,   true),
('석류',         '과일', 'COUNT',  NULL,   NULL, 'FRIDGE',  21,  true),
('밤',           '과일', 'WEIGHT', '봉지', 500,  'FRIDGE',  14,  true),
('대추',         '과일', 'WEIGHT', '봉지', 200,  'PANTRY',  180, true),
('곶감',         '과일', 'COUNT',  '봉지', 10,   'FREEZER', 180, true),
('건포도',       '과일', 'WEIGHT', '봉지', 200,  'PANTRY',  365, true),
('냉동블루베리', '과일', 'WEIGHT', '봉지', 500,  'FREEZER', 365, true),
('냉동망고',     '과일', 'WEIGHT', '봉지', 500,  'FREEZER', 365, true);

-- ============================================================
-- 정육/가공육/달걀 (40)
--   부위명이 돼지/소 양쪽에 존재하는 경우에만 괄호로 보충한다
-- ============================================================
INSERT INTO ingredient (name, category, unit_type, package_name, package_size, default_storage, default_shelf_life_days, is_trackable) VALUES
('삼겹살',       '정육/가공육/달걀', 'WEIGHT', '팩', 500,  'FRIDGE', 3,   true),
('목살',         '정육/가공육/달걀', 'WEIGHT', '팩', 500,  'FRIDGE', 3,   true),
('앞다리살',     '정육/가공육/달걀', 'WEIGHT', '팩', 500,  'FRIDGE', 3,   true),
('뒷다리살',     '정육/가공육/달걀', 'WEIGHT', '팩', 500,  'FRIDGE', 3,   true),
('등심(돼지)',   '정육/가공육/달걀', 'WEIGHT', '팩', 500,  'FRIDGE', 3,   true),
('안심(돼지)',   '정육/가공육/달걀', 'WEIGHT', '팩', 400,  'FRIDGE', 3,   true),
('갈비(돼지)',   '정육/가공육/달걀', 'WEIGHT', '팩', 1000, 'FRIDGE', 3,   true),
('항정살',       '정육/가공육/달걀', 'WEIGHT', '팩', 300,  'FRIDGE', 3,   true),
('가브리살',     '정육/가공육/달걀', 'WEIGHT', '팩', 300,  'FRIDGE', 3,   true),
('다짐육(돼지)', '정육/가공육/달걀', 'WEIGHT', '팩', 300,  'FRIDGE', 2,   true),
('등심(소)',     '정육/가공육/달걀', 'WEIGHT', '팩', 400,  'FRIDGE', 3,   true),
('안심(소)',     '정육/가공육/달걀', 'WEIGHT', '팩', 300,  'FRIDGE', 3,   true),
('갈비(소)',     '정육/가공육/달걀', 'WEIGHT', '팩', 1000, 'FRIDGE', 3,   true),
('다짐육(소)',   '정육/가공육/달걀', 'WEIGHT', '팩', 300,  'FRIDGE', 2,   true),
('채끝',         '정육/가공육/달걀', 'WEIGHT', '팩', 400,  'FRIDGE', 3,   true),
('부채살',       '정육/가공육/달걀', 'WEIGHT', '팩', 400,  'FRIDGE', 3,   true),
('차돌박이',     '정육/가공육/달걀', 'WEIGHT', '팩', 300,  'FRIDGE', 3,   true),
('양지',         '정육/가공육/달걀', 'WEIGHT', '팩', 500,  'FRIDGE', 3,   true),
('사태',         '정육/가공육/달걀', 'WEIGHT', '팩', 500,  'FRIDGE', 3,   true),
('우둔살',       '정육/가공육/달걀', 'WEIGHT', '팩', 500,  'FRIDGE', 3,   true),
('불고기감',     '정육/가공육/달걀', 'WEIGHT', '팩', 500,  'FRIDGE', 2,   true),
('닭가슴살',     '정육/가공육/달걀', 'WEIGHT', '팩', 500,  'FRIDGE', 3,   true),
('닭안심',       '정육/가공육/달걀', 'WEIGHT', '팩', 400,  'FRIDGE', 3,   true),
('닭다리살',     '정육/가공육/달걀', 'WEIGHT', '팩', 500,  'FRIDGE', 3,   true),
('닭봉',         '정육/가공육/달걀', 'WEIGHT', '팩', 500,  'FRIDGE', 3,   true),
('닭날개',       '정육/가공육/달걀', 'WEIGHT', '팩', 500,  'FRIDGE', 3,   true),
('닭볶음탕용',   '정육/가공육/달걀', 'WEIGHT', '팩', 1000, 'FRIDGE', 3,   true),
('생닭',         '정육/가공육/달걀', 'COUNT',  NULL, NULL, 'FRIDGE', 3,   true),
('오리고기',     '정육/가공육/달걀', 'WEIGHT', '팩', 600,  'FRIDGE', 3,   true),
('훈제오리',     '정육/가공육/달걀', 'WEIGHT', '팩', 400,  'FRIDGE', 14,  true),
('곱창',         '정육/가공육/달걀', 'WEIGHT', '팩', 500,  'FRIDGE', 2,   true),
('베이컨',       '정육/가공육/달걀', 'WEIGHT', '팩', 200,  'FRIDGE', 14,  true),
('슬라이스햄',   '정육/가공육/달걀', 'WEIGHT', '팩', 200,  'FRIDGE', 14,  true),
('스팸',         '정육/가공육/달걀', 'WEIGHT', '캔', 200,  'PANTRY', 730, true),
('소시지',       '정육/가공육/달걀', 'WEIGHT', '팩', 300,  'FRIDGE', 21,  true),
('비엔나소시지', '정육/가공육/달걀', 'WEIGHT', '팩', 200,  'FRIDGE', 21,  true),
('살라미',       '정육/가공육/달걀', 'WEIGHT', '팩', 100,  'FRIDGE', 30,  true),
('달걀',         '정육/가공육/달걀', 'COUNT',  '판', 30,   'FRIDGE', 21,  true),
('메추리알',     '정육/가공육/달걀', 'COUNT',  '팩', 20,   'FRIDGE', 14,  true),
('훈제란',       '정육/가공육/달걀', 'COUNT',  '봉지', 10, 'FRIDGE', 14,  true);

-- ============================================================
-- 수산물/건해산 (40)
-- ============================================================
INSERT INTO ingredient (name, category, unit_type, package_name, package_size, default_storage, default_shelf_life_days, is_trackable) VALUES
('고등어',       '수산물/건해산', 'COUNT',  '손',   2,    'FRIDGE',  2,   true),
('갈치',         '수산물/건해산', 'COUNT',  NULL,   NULL, 'FRIDGE',  2,   true),
('삼치',         '수산물/건해산', 'COUNT',  NULL,   NULL, 'FRIDGE',  2,   true),
('조기',         '수산물/건해산', 'COUNT',  NULL,   NULL, 'FRIDGE',  2,   true),
('명태',         '수산물/건해산', 'COUNT',  NULL,   NULL, 'FRIDGE',  2,   true),
('동태',         '수산물/건해산', 'COUNT',  NULL,   NULL, 'FREEZER', 90,  true),
('코다리',       '수산물/건해산', 'COUNT',  NULL,   NULL, 'FRIDGE',  5,   true),
('황태채',       '수산물/건해산', 'WEIGHT', '봉지', 100,  'PANTRY',  180, true),
('임연수어',     '수산물/건해산', 'COUNT',  NULL,   NULL, 'FRIDGE',  2,   true),
('가자미',       '수산물/건해산', 'COUNT',  NULL,   NULL, 'FRIDGE',  2,   true),
('연어',         '수산물/건해산', 'WEIGHT', '팩',   300,  'FRIDGE',  2,   true),
('훈제연어',     '수산물/건해산', 'WEIGHT', '팩',   100,  'FRIDGE',  7,   true),
('우럭',         '수산물/건해산', 'COUNT',  NULL,   NULL, 'FRIDGE',  2,   true),
('장어',         '수산물/건해산', 'WEIGHT', '팩',   500,  'FRIDGE',  2,   true),
('새우',         '수산물/건해산', 'WEIGHT', '팩',   300,  'FRIDGE',  2,   true),
('냉동새우',     '수산물/건해산', 'WEIGHT', '봉지', 500,  'FREEZER', 180, true),
('오징어',       '수산물/건해산', 'COUNT',  NULL,   NULL, 'FRIDGE',  2,   true),
('낙지',         '수산물/건해산', 'COUNT',  NULL,   NULL, 'FRIDGE',  1,   true),
('주꾸미',       '수산물/건해산', 'WEIGHT', '팩',   500,  'FRIDGE',  1,   true),
('문어',         '수산물/건해산', 'WEIGHT', '팩',   500,  'FRIDGE',  2,   true),
('바지락',       '수산물/건해산', 'WEIGHT', '봉지', 500,  'FRIDGE',  2,   true),
('홍합',         '수산물/건해산', 'WEIGHT', '봉지', 1000, 'FRIDGE',  2,   true),
('굴',           '수산물/건해산', 'WEIGHT', '팩',   200,  'FRIDGE',  2,   true),
('가리비',       '수산물/건해산', 'COUNT',  '팩',   6,    'FRIDGE',  2,   true),
('전복',         '수산물/건해산', 'COUNT',  '팩',   5,    'FRIDGE',  3,   true),
('꽃게',         '수산물/건해산', 'COUNT',  NULL,   NULL, 'FRIDGE',  2,   true),
('대게',         '수산물/건해산', 'COUNT',  NULL,   NULL, 'FRIDGE',  2,   true),
('게맛살',       '수산물/건해산', 'WEIGHT', '팩',   200,  'FRIDGE',  30,  true),
('어묵',         '수산물/건해산', 'WEIGHT', '봉지', 500,  'FRIDGE',  14,  true),
('볶음용멸치',   '수산물/건해산', 'WEIGHT', '봉지', 300,  'FREEZER', 180, true),
('국물용멸치',   '수산물/건해산', 'WEIGHT', '봉지', 500,  'FREEZER', 180, true),
('건새우',       '수산물/건해산', 'WEIGHT', '봉지', 100,  'FREEZER', 180, true),
('마른오징어',   '수산물/건해산', 'COUNT',  '봉지', 3,    'PANTRY',  180, true),
('쥐포',         '수산물/건해산', 'COUNT',  '봉지', 5,    'PANTRY',  180, true),
('미역',         '수산물/건해산', 'WEIGHT', '봉지', 100,  'PANTRY',  365, true),
('다시마',       '수산물/건해산', 'WEIGHT', '봉지', 100,  'PANTRY',  365, true),
('김',           '수산물/건해산', 'COUNT',  '봉지', 10,   'PANTRY',  90,  true),
('조미김',       '수산물/건해산', 'COUNT',  '봉지', 12,   'PANTRY',  90,  true),
('톳',           '수산물/건해산', 'WEIGHT', '봉지', 200,  'FRIDGE',  7,   true),
('미역줄기',     '수산물/건해산', 'WEIGHT', '팩',   300,  'FRIDGE',  10,  true);

-- ============================================================
-- 두부/콩/묵 (15)
-- ============================================================
INSERT INTO ingredient (name, category, unit_type, package_name, package_size, default_storage, default_shelf_life_days, is_trackable) VALUES
('두부(부침용)', '두부/콩/묵', 'WEIGHT', '모',   300, 'FRIDGE',  10,  true),
('두부(찌개용)', '두부/콩/묵', 'WEIGHT', '모',   300, 'FRIDGE',  10,  true),
('순두부',       '두부/콩/묵', 'WEIGHT', '봉지', 350, 'FRIDGE',  7,   true),
('연두부',       '두부/콩/묵', 'WEIGHT', '팩',   300, 'FRIDGE',  10,  true),
('유부',         '두부/콩/묵', 'WEIGHT', '봉지', 100, 'FRIDGE',  30,  true),
('콩나물',       '두부/콩/묵', 'WEIGHT', '봉지', 300, 'FRIDGE',  5,   true),
('숙주',         '두부/콩/묵', 'WEIGHT', '봉지', 300, 'FRIDGE',  3,   true),
('도토리묵',     '두부/콩/묵', 'WEIGHT', '모',   400, 'FRIDGE',  7,   true),
('청포묵',       '두부/콩/묵', 'WEIGHT', '모',   400, 'FRIDGE',  7,   true),
('백태',         '두부/콩/묵', 'WEIGHT', '봉지', 500, 'PANTRY',  365, true),
('서리태',       '두부/콩/묵', 'WEIGHT', '봉지', 500, 'PANTRY',  365, true),
('강낭콩',       '두부/콩/묵', 'WEIGHT', '봉지', 500, 'PANTRY',  365, true),
('병아리콩',     '두부/콩/묵', 'WEIGHT', '봉지', 500, 'PANTRY',  365, true),
('렌틸콩',       '두부/콩/묵', 'WEIGHT', '봉지', 500, 'PANTRY',  365, true),
('완두콩',       '두부/콩/묵', 'WEIGHT', '봉지', 300, 'FREEZER', 180, true);

-- ============================================================
-- 우유/유제품 (20)
-- ============================================================
INSERT INTO ingredient (name, category, unit_type, package_name, package_size, default_storage, default_shelf_life_days, is_trackable) VALUES
('우유',           '우유/유제품', 'VOLUME', '팩',   1000, 'FRIDGE',  12,  true),
('저지방우유',     '우유/유제품', 'VOLUME', '팩',   1000, 'FRIDGE',  12,  true),
('멸균우유',       '우유/유제품', 'VOLUME', '팩',   1000, 'PANTRY',  180, true),
('플레인요거트',   '우유/유제품', 'WEIGHT', '팩',   450,  'FRIDGE',  14,  true),
('떠먹는요거트',   '우유/유제품', 'COUNT',  '팩',   4,    'FRIDGE',  14,  true),
('마시는요구르트', '우유/유제품', 'VOLUME', '병',   500,  'FRIDGE',  14,  true),
('그릭요거트',     '우유/유제품', 'WEIGHT', '팩',   400,  'FRIDGE',  14,  true),
('슬라이스치즈',   '우유/유제품', 'COUNT',  '봉지', 10,   'FRIDGE',  60,  true),
('모짜렐라치즈',   '우유/유제품', 'WEIGHT', '봉지', 500,  'FRIDGE',  30,  true),
('체다치즈',       '우유/유제품', 'WEIGHT', '팩',   200,  'FRIDGE',  60,  true),
('파마산치즈',     '우유/유제품', 'WEIGHT', '통',   100,  'FRIDGE',  180, true),
('크림치즈',       '우유/유제품', 'WEIGHT', '팩',   200,  'FRIDGE',  30,  true),
('리코타치즈',     '우유/유제품', 'WEIGHT', '팩',   200,  'FRIDGE',  14,  true),
('버터',           '우유/유제품', 'WEIGHT', '팩',   450,  'FRIDGE',  180, true),
('무염버터',       '우유/유제품', 'WEIGHT', '팩',   450,  'FRIDGE',  180, true),
('생크림',         '우유/유제품', 'VOLUME', '팩',   500,  'FRIDGE',  14,  true),
('휘핑크림',       '우유/유제품', 'VOLUME', '캔',   250,  'FRIDGE',  30,  true),
('사워크림',       '우유/유제품', 'WEIGHT', '팩',   200,  'FRIDGE',  21,  true),
('연유',           '우유/유제품', 'VOLUME', '튜브', 250,  'FRIDGE',  180, true),
('아이스크림',     '우유/유제품', 'VOLUME', '통',   474,  'FREEZER', 365, true);

-- ============================================================
-- 쌀/잡곡/견과 (25)
-- ============================================================
INSERT INTO ingredient (name, category, unit_type, package_name, package_size, default_storage, default_shelf_life_days, is_trackable) VALUES
('쌀',           '쌀/잡곡/견과', 'WEIGHT', '포',   10000, 'PANTRY',  180, true),
('현미',         '쌀/잡곡/견과', 'WEIGHT', '봉지', 4000,  'PANTRY',  180, true),
('찹쌀',         '쌀/잡곡/견과', 'WEIGHT', '봉지', 1000,  'PANTRY',  180, true),
('보리쌀',       '쌀/잡곡/견과', 'WEIGHT', '봉지', 1000,  'PANTRY',  180, true),
('귀리',         '쌀/잡곡/견과', 'WEIGHT', '봉지', 1000,  'PANTRY',  180, true),
('흑미',         '쌀/잡곡/견과', 'WEIGHT', '봉지', 1000,  'PANTRY',  180, true),
('수수',         '쌀/잡곡/견과', 'WEIGHT', '봉지', 500,   'PANTRY',  180, true),
('조',           '쌀/잡곡/견과', 'WEIGHT', '봉지', 500,   'PANTRY',  180, true),
('퀴노아',       '쌀/잡곡/견과', 'WEIGHT', '봉지', 500,   'PANTRY',  180, true),
('오트밀',       '쌀/잡곡/견과', 'WEIGHT', '봉지', 1000,  'PANTRY',  180, true),
('밀가루',       '쌀/잡곡/견과', 'WEIGHT', '봉지', 1000,  'PANTRY',  365, true),
('부침가루',     '쌀/잡곡/견과', 'WEIGHT', '봉지', 1000,  'PANTRY',  365, true),
('튀김가루',     '쌀/잡곡/견과', 'WEIGHT', '봉지', 1000,  'PANTRY',  365, true),
('전분가루',     '쌀/잡곡/견과', 'WEIGHT', '봉지', 500,   'PANTRY',  365, true),
('쌀가루',       '쌀/잡곡/견과', 'WEIGHT', '봉지', 500,   'FREEZER', 180, true),
('빵가루',       '쌀/잡곡/견과', 'WEIGHT', '봉지', 200,   'PANTRY',  180, true),
('미숫가루',     '쌀/잡곡/견과', 'WEIGHT', '봉지', 500,   'PANTRY',  180, true),
('아몬드',       '쌀/잡곡/견과', 'WEIGHT', '봉지', 200,   'PANTRY',  180, true),
('호두',         '쌀/잡곡/견과', 'WEIGHT', '봉지', 200,   'PANTRY',  180, true),
('캐슈넛',       '쌀/잡곡/견과', 'WEIGHT', '봉지', 200,   'PANTRY',  180, true),
('땅콩',         '쌀/잡곡/견과', 'WEIGHT', '봉지', 200,   'PANTRY',  180, true),
('잣',           '쌀/잡곡/견과', 'WEIGHT', '봉지', 100,   'FREEZER', 180, true),
('해바라기씨',   '쌀/잡곡/견과', 'WEIGHT', '봉지', 200,   'PANTRY',  180, true),
('호박씨',       '쌀/잡곡/견과', 'WEIGHT', '봉지', 200,   'PANTRY',  180, true),
('은행',         '쌀/잡곡/견과', 'WEIGHT', '봉지', 200,   'FRIDGE',  30,  true);

-- ============================================================
-- 면/빵/통조림 (25)
-- ============================================================
INSERT INTO ingredient (name, category, unit_type, package_name, package_size, default_storage, default_shelf_life_days, is_trackable) VALUES
('라면',         '면/빵/통조림', 'COUNT',  '봉지', 5,    'PANTRY', 180, true),
('컵라면',       '면/빵/통조림', 'COUNT',  NULL,   NULL, 'PANTRY', 180, true),
('소면',         '면/빵/통조림', 'WEIGHT', '봉지', 500,  'PANTRY', 365, true),
('칼국수면',     '면/빵/통조림', 'WEIGHT', '봉지', 400,  'FRIDGE', 14,  true),
('우동면',       '면/빵/통조림', 'WEIGHT', '봉지', 400,  'FRIDGE', 30,  true),
('냉면사리',     '면/빵/통조림', 'WEIGHT', '봉지', 400,  'FRIDGE', 30,  true),
('쫄면',         '면/빵/통조림', 'WEIGHT', '봉지', 400,  'FRIDGE', 30,  true),
('메밀면',       '면/빵/통조림', 'WEIGHT', '봉지', 300,  'PANTRY', 365, true),
('당면',         '면/빵/통조림', 'WEIGHT', '봉지', 500,  'PANTRY', 365, true),
('스파게티면',   '면/빵/통조림', 'WEIGHT', '봉지', 500,  'PANTRY', 730, true),
('펜네',         '면/빵/통조림', 'WEIGHT', '봉지', 500,  'PANTRY', 730, true),
('떡국떡',       '면/빵/통조림', 'WEIGHT', '봉지', 500,  'FRIDGE', 14,  true),
('떡볶이떡',     '면/빵/통조림', 'WEIGHT', '봉지', 500,  'FRIDGE', 14,  true),
('식빵',         '면/빵/통조림', 'COUNT',  '봉지', 8,    'PANTRY', 4,   true),
('모닝빵',       '면/빵/통조림', 'COUNT',  '봉지', 8,    'PANTRY', 4,   true),
('바게트',       '면/빵/통조림', 'COUNT',  NULL,   NULL, 'PANTRY', 3,   true),
('크루아상',     '면/빵/통조림', 'COUNT',  '봉지', 4,    'PANTRY', 3,   true),
('토르티야',     '면/빵/통조림', 'COUNT',  '봉지', 8,    'FRIDGE', 60,  true),
('참치캔',       '면/빵/통조림', 'COUNT',  NULL,   NULL, 'PANTRY', 730, true),
('꽁치캔',       '면/빵/통조림', 'COUNT',  NULL,   NULL, 'PANTRY', 730, true),
('골뱅이캔',     '면/빵/통조림', 'COUNT',  NULL,   NULL, 'PANTRY', 730, true),
('옥수수캔',     '면/빵/통조림', 'COUNT',  NULL,   NULL, 'PANTRY', 730, true),
('토마토홀캔',   '면/빵/통조림', 'COUNT',  NULL,   NULL, 'PANTRY', 730, true),
('파인애플캔',   '면/빵/통조림', 'COUNT',  NULL,   NULL, 'PANTRY', 730, true),
('코코넛밀크',   '면/빵/통조림', 'VOLUME', '캔',   400,  'PANTRY', 365, true);

-- ============================================================
-- 양념/오일 (45)
--   잔량 정량 관리가 무의미하므로 전 품목 is_trackable = false, shelf_life = NULL (D-004 부가결정)
-- ============================================================
INSERT INTO ingredient (name, category, unit_type, package_name, package_size, default_storage, default_shelf_life_days, is_trackable) VALUES
('소금',         '양념/오일', 'WEIGHT', NULL,   NULL, 'PANTRY',  NULL, false),
('굵은소금',     '양념/오일', 'WEIGHT', NULL,   NULL, 'PANTRY',  NULL, false),
('설탕',         '양념/오일', 'WEIGHT', NULL,   NULL, 'PANTRY',  NULL, false),
('흑설탕',       '양념/오일', 'WEIGHT', NULL,   NULL, 'PANTRY',  NULL, false),
('후추',         '양념/오일', 'WEIGHT', NULL,   NULL, 'PANTRY',  NULL, false),
('통후추',       '양념/오일', 'WEIGHT', NULL,   NULL, 'PANTRY',  NULL, false),
('고춧가루',     '양념/오일', 'WEIGHT', '봉지', 500,  'FREEZER', NULL, false),
('고추장',       '양념/오일', 'WEIGHT', '통',   500,  'FRIDGE',  NULL, false),
('된장',         '양념/오일', 'WEIGHT', '통',   500,  'FRIDGE',  NULL, false),
('쌈장',         '양념/오일', 'WEIGHT', '통',   500,  'FRIDGE',  NULL, false),
('초고추장',     '양념/오일', 'WEIGHT', '통',   300,  'FRIDGE',  NULL, false),
('진간장',       '양념/오일', 'VOLUME', '병',   500,  'PANTRY',  NULL, false),
('국간장',       '양념/오일', 'VOLUME', '병',   500,  'PANTRY',  NULL, false),
('양조간장',     '양념/오일', 'VOLUME', '병',   500,  'PANTRY',  NULL, false),
('식초',         '양념/오일', 'VOLUME', '병',   500,  'PANTRY',  NULL, false),
('맛술',         '양념/오일', 'VOLUME', '병',   500,  'PANTRY',  NULL, false),
('청주',         '양념/오일', 'VOLUME', '병',   500,  'PANTRY',  NULL, false),
('참기름',       '양념/오일', 'VOLUME', '병',   320,  'PANTRY',  NULL, false),
('들기름',       '양념/오일', 'VOLUME', '병',   320,  'FRIDGE',  NULL, false),
('식용유',       '양념/오일', 'VOLUME', '병',   900,  'PANTRY',  NULL, false),
('카놀라유',     '양념/오일', 'VOLUME', '병',   900,  'PANTRY',  NULL, false),
('올리브유',     '양념/오일', 'VOLUME', '병',   500,  'PANTRY',  NULL, false),
('참깨',         '양념/오일', 'WEIGHT', '봉지', 100,  'PANTRY',  NULL, false),
('들깨가루',     '양념/오일', 'WEIGHT', '봉지', 200,  'FREEZER', NULL, false),
('물엿',         '양념/오일', 'VOLUME', '통',   700,  'PANTRY',  NULL, false),
('올리고당',     '양념/오일', 'VOLUME', '통',   700,  'PANTRY',  NULL, false),
('꿀',           '양념/오일', 'WEIGHT', '병',   500,  'PANTRY',  NULL, false),
('매실청',       '양념/오일', 'VOLUME', '병',   1000, 'FRIDGE',  NULL, false),
('멸치액젓',     '양념/오일', 'VOLUME', '병',   500,  'PANTRY',  NULL, false),
('까나리액젓',   '양념/오일', 'VOLUME', '병',   500,  'PANTRY',  NULL, false),
('새우젓',       '양념/오일', 'WEIGHT', '통',   300,  'FRIDGE',  NULL, false),
('굴소스',       '양념/오일', 'VOLUME', '병',   500,  'FRIDGE',  NULL, false),
('케첩',         '양념/오일', 'VOLUME', '병',   500,  'FRIDGE',  NULL, false),
('마요네즈',     '양념/오일', 'VOLUME', '병',   500,  'FRIDGE',  NULL, false),
('머스타드',     '양념/오일', 'VOLUME', '병',   250,  'FRIDGE',  NULL, false),
('돈까스소스',   '양념/오일', 'VOLUME', '병',   300,  'FRIDGE',  NULL, false),
('칠리소스',     '양념/오일', 'VOLUME', '병',   300,  'FRIDGE',  NULL, false),
('스리라차',     '양념/오일', 'VOLUME', '병',   250,  'FRIDGE',  NULL, false),
('연겨자',       '양념/오일', 'VOLUME', '튜브', 100,  'FRIDGE',  NULL, false),
('와사비',       '양념/오일', 'VOLUME', '튜브', 50,   'FRIDGE',  NULL, false),
('다시다',       '양념/오일', 'WEIGHT', '봉지', 300,  'PANTRY',  NULL, false),
('치킨스톡',     '양념/오일', 'WEIGHT', '통',   200,  'PANTRY',  NULL, false),
('카레가루',     '양념/오일', 'WEIGHT', '봉지', 100,  'PANTRY',  NULL, false),
('계핏가루',     '양념/오일', 'WEIGHT', '통',   50,   'PANTRY',  NULL, false),
('월계수잎',     '양념/오일', 'WEIGHT', '봉지', 10,   'PANTRY',  NULL, false);

-- ============================================================
-- 김치/반찬 (18)
-- ============================================================
INSERT INTO ingredient (name, category, unit_type, package_name, package_size, default_storage, default_shelf_life_days, is_trackable) VALUES
('배추김치',     '김치/반찬', 'WEIGHT', NULL,   NULL, 'FRIDGE', 90,  true),
('묵은지',       '김치/반찬', 'WEIGHT', '통',   1000, 'FRIDGE', 180, true),
('총각김치',     '김치/반찬', 'WEIGHT', '통',   1000, 'FRIDGE', 60,  true),
('깍두기',       '김치/반찬', 'WEIGHT', '통',   1000, 'FRIDGE', 60,  true),
('백김치',       '김치/반찬', 'WEIGHT', '통',   1000, 'FRIDGE', 60,  true),
('열무김치',     '김치/반찬', 'WEIGHT', '통',   1000, 'FRIDGE', 30,  true),
('파김치',       '김치/반찬', 'WEIGHT', '통',   500,  'FRIDGE', 30,  true),
('갓김치',       '김치/반찬', 'WEIGHT', '통',   500,  'FRIDGE', 30,  true),
('오이소박이',   '김치/반찬', 'WEIGHT', '통',   500,  'FRIDGE', 14,  true),
('동치미',       '김치/반찬', 'VOLUME', '통',   2000, 'FRIDGE', 30,  true),
('명란젓',       '김치/반찬', 'WEIGHT', '팩',   200,  'FRIDGE', 30,  true),
('오징어젓',     '김치/반찬', 'WEIGHT', '팩',   200,  'FRIDGE', 30,  true),
('깻잎장아찌',   '김치/반찬', 'WEIGHT', '팩',   200,  'FRIDGE', 60,  true),
('마늘장아찌',   '김치/반찬', 'WEIGHT', '통',   500,  'FRIDGE', 180, true),
('단무지',       '김치/반찬', 'WEIGHT', '봉지', 300,  'FRIDGE', 30,  true),
('무말랭이',     '김치/반찬', 'WEIGHT', '봉지', 200,  'PANTRY', 180, true),
('멸치볶음',     '김치/반찬', 'WEIGHT', '팩',   200,  'FRIDGE', 7,   true),
('콩자반',       '김치/반찬', 'WEIGHT', '팩',   200,  'FRIDGE', 7,   true);

-- ============================================================
-- 냉동/밀키트 (18)
-- ============================================================
INSERT INTO ingredient (name, category, unit_type, package_name, package_size, default_storage, default_shelf_life_days, is_trackable) VALUES
('냉동만두',       '냉동/밀키트', 'WEIGHT', '봉지', 400,  'FREEZER', 365, true),
('물만두',         '냉동/밀키트', 'WEIGHT', '봉지', 400,  'FREEZER', 365, true),
('군만두',         '냉동/밀키트', 'WEIGHT', '봉지', 400,  'FREEZER', 365, true),
('냉동돈까스',     '냉동/밀키트', 'COUNT',  '봉지', 5,    'FREEZER', 365, true),
('냉동치킨너겟',   '냉동/밀키트', 'WEIGHT', '봉지', 500,  'FREEZER', 365, true),
('냉동핫도그',     '냉동/밀키트', 'COUNT',  '봉지', 5,    'FREEZER', 365, true),
('냉동떡갈비',     '냉동/밀키트', 'COUNT',  '봉지', 4,    'FREEZER', 365, true),
('냉동완자',       '냉동/밀키트', 'WEIGHT', '봉지', 500,  'FREEZER', 365, true),
('냉동피자',       '냉동/밀키트', 'COUNT',  NULL,   NULL, 'FREEZER', 365, true),
('냉동감자튀김',   '냉동/밀키트', 'WEIGHT', '봉지', 1000, 'FREEZER', 365, true),
('냉동볶음밥',     '냉동/밀키트', 'COUNT',  '봉지', 3,    'FREEZER', 365, true),
('냉동곰탕',       '냉동/밀키트', 'VOLUME', '봉지', 600,  'FREEZER', 365, true),
('냉동브로콜리',   '냉동/밀키트', 'WEIGHT', '봉지', 500,  'FREEZER', 365, true),
('냉동믹스채소',   '냉동/밀키트', 'WEIGHT', '봉지', 500,  'FREEZER', 365, true),
('냉동대파',       '냉동/밀키트', 'WEIGHT', '봉지', 300,  'FREEZER', 180, true),
('즉석밥',         '냉동/밀키트', 'COUNT',  '팩',   3,    'PANTRY',  270, true),
('부대찌개밀키트', '냉동/밀키트', 'COUNT',  NULL,   NULL, 'FRIDGE',  7,   true),
('밀푀유나베밀키트', '냉동/밀키트', 'COUNT', NULL,   NULL, 'FRIDGE',  7,   true);

-- ============================================================
-- 커피/차/음료 (15)
--   원두·믹스·티백류는 잔량 관리가 무의미하므로 false, 용량으로 소비하는 음료만 true
-- ============================================================
INSERT INTO ingredient (name, category, unit_type, package_name, package_size, default_storage, default_shelf_life_days, is_trackable) VALUES
('원두커피',       '커피/차/음료', 'WEIGHT', '봉지', 200,  'PANTRY', NULL, false),
('인스턴트커피',   '커피/차/음료', 'WEIGHT', '병',   100,  'PANTRY', NULL, false),
('믹스커피',       '커피/차/음료', 'COUNT',  '박스', 100,  'PANTRY', NULL, false),
('캡슐커피',       '커피/차/음료', 'COUNT',  '박스', 10,   'PANTRY', NULL, false),
('녹차티백',       '커피/차/음료', 'COUNT',  '박스', 25,   'PANTRY', NULL, false),
('홍차티백',       '커피/차/음료', 'COUNT',  '박스', 25,   'PANTRY', NULL, false),
('보리차티백',     '커피/차/음료', 'COUNT',  '박스', 30,   'PANTRY', NULL, false),
('둥굴레차',       '커피/차/음료', 'COUNT',  '박스', 30,   'PANTRY', NULL, false),
('캐모마일티백',   '커피/차/음료', 'COUNT',  '박스', 20,   'PANTRY', NULL, false),
('오렌지주스',     '커피/차/음료', 'VOLUME', '팩',   1000, 'FRIDGE', 10,   true),
('사과주스',       '커피/차/음료', 'VOLUME', '팩',   1000, 'FRIDGE', 10,   true),
('두유',           '커피/차/음료', 'VOLUME', '팩',   190,  'PANTRY', 180,  true),
('콜라',           '커피/차/음료', 'VOLUME', '병',   1500, 'PANTRY', 180,  true),
('사이다',         '커피/차/음료', 'VOLUME', '병',   1500, 'PANTRY', 180,  true),
('탄산수',         '커피/차/음료', 'VOLUME', '병',   500,  'PANTRY', 180,  true);

-- ============================================================
-- 기타 (9)
-- ============================================================
INSERT INTO ingredient (name, category, unit_type, package_name, package_size, default_storage, default_shelf_life_days, is_trackable) VALUES
('베이킹파우더',   '기타', 'WEIGHT', '봉지', 100, 'PANTRY', NULL, false),
('베이킹소다',     '기타', 'WEIGHT', '봉지', 100, 'PANTRY', NULL, false),
('드라이이스트',   '기타', 'WEIGHT', '봉지', 50,  'FRIDGE', NULL, false),
('바닐라익스트랙', '기타', 'VOLUME', '병',   60,  'PANTRY', NULL, false),
('식용색소',       '기타', 'VOLUME', '병',   30,  'PANTRY', NULL, false),
('젤라틴',         '기타', 'WEIGHT', '봉지', 100, 'PANTRY', 365,  true),
('한천가루',       '기타', 'WEIGHT', '봉지', 100, 'PANTRY', 365,  true),
('초콜릿',         '기타', 'WEIGHT', '봉지', 200, 'PANTRY', 180,  true),
('코코아가루',     '기타', 'WEIGHT', '봉지', 200, 'PANTRY', 180,  true);
