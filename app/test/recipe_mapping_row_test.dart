import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen/features/recipe/recipe_mapping_row.dart';
import 'package:smart_kitchen/features/recipe/recipe_models.dart';

/// 매핑 확인 화면의 기본값 규칙 (D-007 — 자동 확정 금지, D-004 — base_unit 고정)
void main() {
  RecipeMasterIngredient ingredient({
    String rawText = '두부 20g(2×2×2cm)',
    String parsedName = '두부',
    num? parsedQty = 20,
    String? parsedUnit = 'g',
    MatchedIngredient? matched,
  }) {
    return RecipeMasterIngredient(
      rawText: rawText,
      parsedName: parsedName,
      parsedQty: parsedQty,
      parsedUnit: parsedUnit,
      matched: matched,
    );
  }

  const tofu = MatchedIngredient(id: 171, name: '두부(부침용)', unitType: 'WEIGHT');

  test('매핑됐고 원문 수량이 base_unit과 같은 축이면 그대로 포함한다', () {
    final row = MappingRow(ingredient(matched: tofu));

    expect(row.included, isTrue);
    expect(row.quantity, 20);
    expect(row.ingredientId, 171);
    expect(row.needsAttention, isFalse);
  });

  test('원문에 수량이 없으면(참깨 약간) 제외 상태로 둔다', () {
    final row = MappingRow(ingredient(
      rawText: '참깨 약간',
      parsedName: '참깨',
      parsedQty: null,
      parsedUnit: null,
      matched: const MatchedIngredient(id: 90, name: '참깨', unitType: 'WEIGHT'),
    ));

    expect(row.included, isFalse);
    expect(row.quantity, isNull);
    // 재료는 정해져 있으니 "재료 지정 필요" 경고 대상은 아니다
    expect(row.needsAttention, isFalse);
  });

  test('원문 단위 축이 다르면(1개 vs g) 수량을 옮기지 않는다', () {
    final row = MappingRow(ingredient(
      rawText: '새송이버섯(1개)',
      parsedName: '새송이버섯',
      parsedQty: 1,
      parsedUnit: '개',
      matched: const MatchedIngredient(id: 55, name: '새송이버섯', unitType: 'WEIGHT'),
    ));

    expect(row.included, isFalse);
    expect(row.quantity, isNull);
  });

  test('매칭에 실패한 재료는 사용자가 지정하기 전까지 경고 대상이다', () {
    final row = MappingRow(ingredient(
      rawText: '날콩가루 7g(1⅓작은술)',
      parsedName: '날콩가루',
      parsedQty: 7,
      matched: null,
    ));

    expect(row.needsIngredient, isTrue);
    expect(row.needsAttention, isTrue);
    expect(row.included, isFalse);

    row.exclude();
    expect(row.needsAttention, isFalse, reason: '사용자가 제외를 고르면 더 묻지 않는다');
    expect(row.included, isFalse);
  });

  test('재료를 지정하면 수량은 다시 확인받는다', () {
    final row = MappingRow(ingredient(matched: tofu));
    expect(row.included, isTrue);

    row.assign(id: 172, name: '두부(찌개용)', unitType: 'WEIGHT');
    expect(row.included, isFalse, reason: '재료가 바뀌면 단위 축도 바뀔 수 있다');
    expect(row.quantity, isNull);

    row.setQuantity(30);
    expect(row.included, isTrue);
    expect(row.quantity, 30);
  });

  test('포함으로 확정한 줄만 API-31 요청에 담는다', () {
    final rows = [
      MappingRow(ingredient(matched: tofu)),
      MappingRow(ingredient(
        rawText: '참깨 약간',
        parsedQty: null,
        parsedUnit: null,
        matched: const MatchedIngredient(id: 90, name: '참깨', unitType: 'WEIGHT'),
      )),
      MappingRow(ingredient(rawText: '요리당 2g', parsedName: '요리당', matched: null)),
    ];

    final items = toRequestItems(rows);
    expect(items, hasLength(1));
    expect(items.single.ingredientId, 171);
    expect(items.single.quantity, 20);
  });

  test('같은 재료를 두 번 포함하면 중복으로 잡는다', () {
    const cocoa = MatchedIngredient(id: 300, name: '코코아가루', unitType: 'WEIGHT');
    final rows = [
      MappingRow(ingredient(rawText: '무가당 코코아가루① 12g', parsedQty: 12, matched: cocoa)),
      MappingRow(ingredient(rawText: '무가당 코코아가루② 12g', parsedQty: 12, matched: cocoa)),
      MappingRow(ingredient(matched: tofu)),
    ];

    expect(duplicatedIngredientIds(rows), {300});

    rows[1].exclude();
    expect(duplicatedIngredientIds(rows), isEmpty);
  });
}
