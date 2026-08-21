// 장보기 도메인 모델. 서버 응답(API-50~53)을 그대로 옮긴다.

import '../ingredient/ingredient_models.dart' show formatQuantity, unitLabelOf;
import '../inventory/inventory_models.dart';

/// 항목 출처. SHORTAGE는 계획 등록에서 부족분으로 담긴 것 (D-010)
enum ShoppingItemSource { manual, shortage }

extension ShoppingItemSourceX on ShoppingItemSource {
  String get label => switch (this) {
        ShoppingItemSource.manual => '직접',
        ShoppingItemSource.shortage => '부족분',
      };

  static ShoppingItemSource fromCode(String? code) =>
      code == 'SHORTAGE' ? ShoppingItemSource.shortage : ShoppingItemSource.manual;
}

class ShoppingItem {
  ShoppingItem({
    required this.id,
    required this.ingredientId,
    required this.name,
    required this.unitType,
    required this.quantity,
    required this.isChecked,
    required this.source,
    required this.packageName,
    required this.packageSize,
  });

  final int id;
  final int ingredientId;
  final String name;
  final String unitType;
  final num quantity;
  final bool isChecked;
  final ShoppingItemSource source;

  /// 표시 전용 포장 단위 — "300g(1모)"의 괄호 부분 (D-004)
  final String? packageName;
  final num? packageSize;

  String get unitLabel => unitLabelOf(unitType);

  /// 300g(1모). 포장 정보가 없으면 수량만
  String get quantityLabel {
    final base = '${formatQuantity(quantity)}$unitLabel';
    final size = packageSize;
    final name = packageName;
    if (size == null || name == null || size <= 0) return base;
    return '$base(${formatQuantity(quantity / size)}$name)';
  }

  ShoppingItem copyWith({num? quantity, bool? isChecked}) => ShoppingItem(
        id: id,
        ingredientId: ingredientId,
        name: name,
        unitType: unitType,
        quantity: quantity ?? this.quantity,
        isChecked: isChecked ?? this.isChecked,
        source: source,
        packageName: packageName,
        packageSize: packageSize,
      );

  factory ShoppingItem.fromJson(Map<String, dynamic> json) => ShoppingItem(
        id: json['id'] as int,
        ingredientId: json['ingredientId'] as int,
        name: json['name'] as String? ?? '',
        unitType: json['unitType'] as String? ?? '',
        quantity: json['quantity'] as num? ?? 0,
        isChecked: json['isChecked'] as bool? ?? false,
        source: ShoppingItemSourceX.fromCode(json['source'] as String?),
        packageName: json['packageName'] as String?,
        packageSize: json['packageSize'] as num?,
      );
}

/// API-50. 가구당 하나뿐인 장바구니 (D-009)
class ShoppingList {
  ShoppingList({required this.id, required this.items});

  final int id;
  final List<ShoppingItem> items;

  factory ShoppingList.fromJson(Map<String, dynamic> json) => ShoppingList(
        id: json['id'] as int,
        items: (json['items'] as List<dynamic>? ?? [])
            .map((e) => ShoppingItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// API-53 구매 완료 결과. inventories는 재고 목록(API-20)과 같은 형태다
class ShoppingCompleteResult {
  ShoppingCompleteResult({required this.inventories, required this.carriedOverCount});

  final List<InventoryItemSummary> inventories;

  /// 체크하지 않아 목록에 남은 항목 수
  final int carriedOverCount;

  factory ShoppingCompleteResult.fromJson(Map<String, dynamic> json) => ShoppingCompleteResult(
        inventories: (json['inventories'] as List<dynamic>? ?? [])
            .map((e) => InventoryItemSummary.fromJson(e as Map<String, dynamic>))
            .toList(),
        carriedOverCount: json['carriedOverCount'] as int? ?? 0,
      );
}
