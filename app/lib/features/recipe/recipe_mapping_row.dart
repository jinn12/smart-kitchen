import '../ingredient/ingredient_models.dart' show unitLabelOf;
import 'recipe_models.dart';

/// 매핑 확인 화면의 재료 한 줄. 원문(API-34)에 사용자의 결정을 얹은 상태다.
///
/// 기본값 규칙 (D-007 — 자동 확정 금지):
/// - 배치가 재료를 찾았고 원문 수량이 우리 base_unit과 같은 축이면 그대로 포함한다
/// - 원문에 수량이 없거나(예: "참깨 약간") 단위 축이 다르면 **제외**로 두고,
///   사용자가 수량을 넣어야 포함된다
/// - 재료를 못 찾은 줄은 사용자가 지정하기 전까지 포함될 수 없다
class MappingRow {
  MappingRow(this.source) {
    final matched = source.matched;
    if (matched == null) return;
    ingredientId = matched.id;
    ingredientName = matched.name;
    unitType = matched.unitType;
    final suggested = suggestedQuantity(matched.unitType);
    if (suggested != null) {
      quantity = suggested;
      included = true;
    }
  }

  final RecipeMasterIngredient source;

  int? ingredientId;
  String? ingredientName;
  String? unitType;

  /// 확정된 수량. null이면 아직 정해지지 않았다는 뜻이라 포함할 수 없다
  num? quantity;

  /// 이 줄을 요리 재료로 보낼지
  bool included = false;

  /// 사용자가 "제외"를 눌러 확인을 끝낸 줄 — 경고를 더 띄우지 않는다
  bool dismissed = false;

  String get unitLabel => unitLabelOf(unitType ?? '');

  bool get needsIngredient => ingredientId == null;

  /// 아직 사용자의 결정이 필요한 줄 (빨간 강조 대상)
  bool get needsAttention => needsIngredient && !dismissed;

  /// 원문 수량을 그대로 쓸 수 있으면 그 값을, 아니면 null.
  /// 단위 축이 다르면(예: "새송이버섯 1개"를 g 단위 재료로) 숫자를 옮길 수 없다 (D-004)
  num? suggestedQuantity(String unitType) {
    final qty = source.parsedQty;
    if (qty == null || qty <= 0) return null;
    if (!unitMatchesBaseUnit(source.parsedUnit, unitType)) return null;
    return qty;
  }

  /// 사용자가 우리 재료를 지정했다 (API-10 검색 결과)
  void assign({required int id, required String name, required String unitType}) {
    ingredientId = id;
    ingredientName = name;
    this.unitType = unitType;
    dismissed = false;
    // 재료가 바뀌면 단위 축도 바뀔 수 있으므로 수량은 다시 확인받는다
    quantity = null;
    included = false;
  }

  void setQuantity(num value) {
    quantity = value;
    included = true;
    dismissed = false;
  }

  /// 제외했던 줄을 되돌린다. 수량이 이미 정해져 있을 때만 의미가 있다
  void include() {
    if (ingredientId == null || quantity == null) return;
    included = true;
    dismissed = false;
  }

  void exclude() {
    included = false;
    dismissed = true;
  }
}

/// 포함으로 확정된 줄만 골라 API-31 요청 형태로 바꾼다
List<({int ingredientId, num quantity})> toRequestItems(List<MappingRow> rows) {
  return rows
      .where((r) => r.included && r.ingredientId != null && r.quantity != null)
      .map((r) => (ingredientId: r.ingredientId!, quantity: r.quantity!))
      .toList();
}

/// 같은 재료가 두 번 포함되면 서버가 400으로 막는다 (API-31).
/// 원문에 "코코아가루①/②"처럼 나뉘어 적힌 재료가 한 재료로 매핑되면 실제로 생긴다
Set<int> duplicatedIngredientIds(List<MappingRow> rows) {
  final seen = <int>{};
  final duplicated = <int>{};
  for (final r in rows) {
    if (!r.included || r.ingredientId == null) continue;
    if (!seen.add(r.ingredientId!)) duplicated.add(r.ingredientId!);
  }
  return duplicated;
}
