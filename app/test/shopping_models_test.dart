import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen/features/shopping/shopping_models.dart';

/// 장보기 항목 표기. 수량은 base_unit이고 포장 단위는 괄호로만 보조한다 (D-004)
void main() {
  ShoppingItem item({
    num quantity = 300,
    String unitType = 'WEIGHT',
    String? packageName,
    num? packageSize,
    String source = 'SHORTAGE',
  }) {
    return ShoppingItem.fromJson({
      'id': 1,
      'ingredientId': 171,
      'name': '두부(부침용)',
      'unitType': unitType,
      'quantity': quantity,
      'isChecked': false,
      'source': source,
      'packageName': packageName,
      'packageSize': packageSize,
    });
  }

  test('포장 정보가 있으면 "300g(1모)"로 병기한다', () {
    expect(item(packageName: '모', packageSize: 300).quantityLabel, '300g(1모)');
  });

  test('포장 정보가 없으면 수량만 보여준다', () {
    expect(item().quantityLabel, '300g');
  });

  test('포장 단위로 나누어떨어지지 않으면 소수로 보여준다', () {
    expect(item(quantity: 450, packageName: '모', packageSize: 300).quantityLabel,
        '450g(1.50모)');
  });

  test('packageSize가 0이면 나눗셈을 하지 않는다', () {
    expect(item(packageName: '모', packageSize: 0).quantityLabel, '300g');
  });

  test('출처 칩은 계획 부족분과 직접 추가를 구분한다', () {
    expect(item().source.label, '부족분');
    expect(item(source: 'MANUAL').source.label, '직접');
  });

  test('구매 완료 결과는 반영 재고와 이월 건수를 함께 읽는다', () {
    final result = ShoppingCompleteResult.fromJson({
      'inventories': [
        {
          'ingredientId': 171,
          'name': '두부(부침용)',
          'category': '두부/콩/묵',
          'unitType': 'WEIGHT',
          'storageLocation': 'FRIDGE',
          'totalQuantity': 500,
          'reservedQuantity': 200,
          'availableQuantity': 300,
          'nearestExpiryDate': '2026-08-31',
          'dday': 10,
          'expiryStatus': 'NORMAL',
        }
      ],
      'carriedOverCount': 2,
    });

    expect(result.inventories.single.name, '두부(부침용)');
    expect(result.inventories.single.availableQuantity, 300);
    expect(result.carriedOverCount, 2);
  });
}
