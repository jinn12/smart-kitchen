// 재고 도메인 모델. 서버 응답(API-20/22/24)을 그대로 옮긴다.

/// 유통기한 상태 (R-5, D-020). 당일(dday=0)은 EXPIRING이다.
enum ExpiryStatus { expired, expiring, normal, none }

ExpiryStatus _parseExpiryStatus(String? raw) {
  switch (raw) {
    case 'EXPIRED':
      return ExpiryStatus.expired;
    case 'EXPIRING':
      return ExpiryStatus.expiring;
    case 'NORMAL':
      return ExpiryStatus.normal;
    default:
      return ExpiryStatus.none;
  }
}

/// 보관 장소. 라벨은 IA의 필터 문구(전체/냉장/냉동/실온)를 따른다.
enum StorageLocation { fridge, freezer, pantry }

extension StorageLocationX on StorageLocation {
  String get code => switch (this) {
        StorageLocation.fridge => 'FRIDGE',
        StorageLocation.freezer => 'FREEZER',
        StorageLocation.pantry => 'PANTRY',
      };

  String get label => switch (this) {
        StorageLocation.fridge => '냉장',
        StorageLocation.freezer => '냉동',
        StorageLocation.pantry => '실온',
      };

  static StorageLocation fromCode(String code) => switch (code) {
        'FREEZER' => StorageLocation.freezer,
        'PANTRY' => StorageLocation.pantry,
        _ => StorageLocation.fridge,
      };
}

/// 수량 표시: 소수점이 의미 없으면 정수로 (300.00 -> 300)
String formatQuantity(num value) {
  final d = value.toDouble();
  return d == d.roundToDouble() ? d.round().toString() : d.toStringAsFixed(2);
}

class InventoryItemSummary {
  InventoryItemSummary({
    required this.ingredientId,
    required this.name,
    required this.category,
    required this.unitType,
    required this.storageLocation,
    required this.totalQuantity,
    required this.reservedQuantity,
    required this.availableQuantity,
    required this.nearestExpiryDate,
    required this.dday,
    required this.expiryStatus,
  });

  final int ingredientId;
  final String name;
  final String category;
  final String unitType;
  final StorageLocation storageLocation;
  final num totalQuantity;
  final num reservedQuantity;
  final num availableQuantity;
  final String? nearestExpiryDate;
  final int? dday;
  final ExpiryStatus expiryStatus;

  factory InventoryItemSummary.fromJson(Map<String, dynamic> json) {
    return InventoryItemSummary(
      ingredientId: json['ingredientId'] as int,
      name: json['name'] as String,
      category: json['category'] as String? ?? '',
      unitType: json['unitType'] as String? ?? '',
      storageLocation: StorageLocationX.fromCode(json['storageLocation'] as String? ?? 'FRIDGE'),
      totalQuantity: json['totalQuantity'] as num? ?? 0,
      reservedQuantity: json['reservedQuantity'] as num? ?? 0,
      availableQuantity: json['availableQuantity'] as num? ?? 0,
      nearestExpiryDate: json['nearestExpiryDate'] as String?,
      dday: json['dday'] as int?,
      expiryStatus: _parseExpiryStatus(json['expiryStatus'] as String?),
    );
  }
}

class InventoryBatch {
  InventoryBatch({
    required this.id,
    required this.quantity,
    required this.purchasedAt,
    required this.expiryDate,
    required this.dday,
  });

  final int id;
  final num quantity;
  final String purchasedAt;
  final String? expiryDate;
  final int? dday;

  factory InventoryBatch.fromJson(Map<String, dynamic> json) => InventoryBatch(
        id: json['id'] as int,
        quantity: json['quantity'] as num? ?? 0,
        purchasedAt: json['purchasedAt'] as String? ?? '',
        expiryDate: json['expiryDate'] as String?,
        dday: json['dday'] as int?,
      );
}

class InventoryHistoryEntry {
  InventoryHistoryEntry({
    required this.id,
    required this.type,
    required this.quantity,
    required this.refType,
    required this.createdAt,
  });

  final int id;
  final String type;
  final num quantity;
  final String? refType;
  final String createdAt;

  factory InventoryHistoryEntry.fromJson(Map<String, dynamic> json) => InventoryHistoryEntry(
        id: json['id'] as int,
        type: json['type'] as String? ?? '',
        quantity: json['quantity'] as num? ?? 0,
        refType: json['refType'] as String?,
        createdAt: json['createdAt'] as String? ?? '',
      );

  String get typeLabel => switch (type) {
        'PURCHASE' => '입고',
        'CONSUME' => '차감',
        'DISPOSE' => '폐기',
        'ADJUST' => '수정',
        _ => type,
      };

  String get sourceLabel => switch (refType) {
        'MEAL_PLAN' => '식단 확정',
        'SHOPPING_LIST' => '장보기',
        _ => '직접',
      };
}

class InventoryDetail {
  InventoryDetail({
    required this.summary,
    required this.batches,
    required this.history,
  });

  final InventoryItemSummary summary;
  final List<InventoryBatch> batches;
  final List<InventoryHistoryEntry> history;

  factory InventoryDetail.fromJson(Map<String, dynamic> json) => InventoryDetail(
        summary: InventoryItemSummary.fromJson(json['summary'] as Map<String, dynamic>),
        batches: (json['batches'] as List<dynamic>? ?? [])
            .map((e) => InventoryBatch.fromJson(e as Map<String, dynamic>))
            .toList(),
        history: (json['history'] as List<dynamic>? ?? [])
            .map((e) => InventoryHistoryEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// API-10 검색 결과 (S-13에서 담을 재료 고르기)
class IngredientSearchResult {
  IngredientSearchResult({
    required this.id,
    required this.name,
    required this.category,
    required this.unitType,
    required this.defaultStorage,
    required this.defaultShelfLifeDays,
    required this.isTrackable,
    required this.isCustom,
  });

  final int id;
  final String name;
  final String category;
  final String unitType;

  /// 재고 등록 시 이 장소로 초기화된다 (S-13에서 미리 보여준다)
  final StorageLocation defaultStorage;
  final int? defaultShelfLifeDays;
  final bool isTrackable;
  final bool isCustom;

  factory IngredientSearchResult.fromJson(Map<String, dynamic> json) => IngredientSearchResult(
        id: json['id'] as int,
        name: json['name'] as String,
        category: json['category'] as String? ?? '',
        unitType: json['unitType'] as String? ?? '',
        defaultStorage: StorageLocationX.fromCode(json['defaultStorage'] as String? ?? 'FRIDGE'),
        defaultShelfLifeDays: json['defaultShelfLifeDays'] as int?,
        isTrackable: json['isTrackable'] as bool? ?? true,
        isCustom: json['isCustom'] as bool? ?? false,
      );

  /// 단위 표시. base_unit 고정이라 unitType으로 환산한다 (D-004)
  String get unitLabel => switch (unitType) {
        'WEIGHT' => 'g',
        'VOLUME' => 'ml',
        _ => '개',
      };
}

/// D-017의 13종 (커스텀 등록·검색 필터에서 쓴다)
const ingredientCategories = <String>[
  '채소', '과일', '정육/가공육/달걀', '수산물/건해산', '두부/콩/묵',
  '우유/유제품', '쌀/잡곡/견과', '면/빵/통조림', '양념/오일', '김치/반찬',
  '냉동/밀키트', '커피/차/음료', '기타',
];

/// unitType -> 표시 단위 (요약·상세 공용)
String unitLabelOf(String unitType) => switch (unitType) {
      'WEIGHT' => 'g',
      'VOLUME' => 'ml',
      _ => '개',
    };
