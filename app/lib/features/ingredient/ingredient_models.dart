// 식재료 공통 어휘. 재고·요리·식탁·장보기가 모두 이 위에 얹힌다.
// 단위·수량 표기 규칙(D-004)이 도메인별로 갈라지지 않도록 여기 한 곳에 둔다.

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

/// unitType -> 표시 단위. 수량은 언제나 base_unit이다 (D-004)
String unitLabelOf(String unitType) => switch (unitType) {
      'WEIGHT' => 'g',
      'VOLUME' => 'ml',
      _ => '개',
    };

/// D-017의 13종 (커스텀 등록·검색 필터에서 쓴다)
const ingredientCategories = <String>[
  '채소', '과일', '정육/가공육/달걀', '수산물/건해산', '두부/콩/묵',
  '우유/유제품', '쌀/잡곡/견과', '면/빵/통조림', '양념/오일', '김치/반찬',
  '냉동/밀키트', '커피/차/음료', '기타',
];

/// API-10 검색 결과 (S-13 재고 담기, S-23 요리 재료, S-41 장보기 수동 추가 공용)
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

  String get unitLabel => unitLabelOf(unitType);
}
