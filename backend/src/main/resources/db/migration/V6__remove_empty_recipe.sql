-- RCP_SEQ 799 「채소 커리를 곁들인 팬케익」 제거.
-- 원본 COOKRCP01의 RCP_PARTS_DTLS가 "." 한 글자라 파싱된 재료가 0건이다.
-- 재료가 없으면 재고 예약·부족 판단(R-1)에 쓸 수 없어 요리로서 성립하지 않는다.
-- V5 적재 시 재료 텍스트가 빈 3건(RCP_SEQ 691/692/831)을 제외한 것과 같은 사유이며,
-- 이 건만 빈 문자열이 아니라 "."이어서 걸러지지 않았다.
-- recipe_master_ingredient는 ON DELETE CASCADE로 함께 정리된다 (V4).
DELETE FROM recipe_master WHERE external_seq = '799';
