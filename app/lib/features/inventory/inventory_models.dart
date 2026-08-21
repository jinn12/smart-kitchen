// 재고 도메인 모델. 서버 응답(API-20/22/24)을 그대로 옮긴다.
// 단위·수량·보관 장소 같은 공통 어휘는 features/ingredient/ingredient_models.dart에 있다.

import '../ingredient/ingredient_models.dart';

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
