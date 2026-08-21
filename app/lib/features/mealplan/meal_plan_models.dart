// 식사 계획 도메인 모델. 서버 응답(API-40~43)을 그대로 옮긴다.

import '../../core/date_utils.dart';
import '../ingredient/ingredient_models.dart' show unitLabelOf;

/// 끼니 3종 (D-012). 순서는 서버 enum 선언 순 = 표시 순서
enum MealType { breakfast, lunch, dinner }

extension MealTypeX on MealType {
  String get code => switch (this) {
        MealType.breakfast => 'BREAKFAST',
        MealType.lunch => 'LUNCH',
        MealType.dinner => 'DINNER',
      };

  String get label => switch (this) {
        MealType.breakfast => '아침',
        MealType.lunch => '점심',
        MealType.dinner => '저녁',
      };

  static MealType fromCode(String? code) => switch (code) {
        'BREAKFAST' => MealType.breakfast,
        'DINNER' => MealType.dinner,
        _ => MealType.lunch,
      };
}

/// 계획 상태 (R-1, R-6). CANCELED는 주간 식탁에 오지 않는다 (D-025)
enum MealPlanStatus { planned, confirmed, canceled }

extension MealPlanStatusX on MealPlanStatus {
  String get label => switch (this) {
        MealPlanStatus.planned => '예정',
        MealPlanStatus.confirmed => '완료',
        MealPlanStatus.canceled => '취소',
      };

  static MealPlanStatus fromCode(String? code) => switch (code) {
        'CONFIRMED' => MealPlanStatus.confirmed,
        'CANCELED' => MealPlanStatus.canceled,
        _ => MealPlanStatus.planned,
      };
}

/// API-40 하루의 계획 한 건
class MealSummary {
  MealSummary({
    required this.id,
    required this.mealType,
    required this.recipeName,
    required this.servings,
    required this.status,
  });

  final int id;
  final MealType mealType;
  final String recipeName;
  final int servings;
  final MealPlanStatus status;

  /// 확정(FEFO 차감 완료)된 계획은 되돌릴 수 없다 (R-6)
  bool get cancelable => status == MealPlanStatus.planned;

  factory MealSummary.fromJson(Map<String, dynamic> json) => MealSummary(
        id: json['id'] as int,
        mealType: MealTypeX.fromCode(json['mealType'] as String?),
        recipeName: json['recipeName'] as String? ?? '',
        servings: json['servings'] as int? ?? 1,
        status: MealPlanStatusX.fromCode(json['status'] as String?),
      );
}

/// API-40 하루치. 계획이 없는 날도 빈 배열로 온다
class MealPlanDay {
  MealPlanDay({required this.date, required this.meals});

  final DateTime date;
  final List<MealSummary> meals;

  factory MealPlanDay.fromJson(Map<String, dynamic> json) => MealPlanDay(
        date: parseIsoDate(json['date'] as String),
        meals: (json['meals'] as List<dynamic>? ?? [])
            .map((e) => MealSummary.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// API-41 미리보기의 재료 한 줄
class PreviewIngredient {
  PreviewIngredient({
    required this.ingredientId,
    required this.name,
    required this.unitType,
    required this.requiredQuantity,
    required this.availableQuantity,
    required this.shortageQuantity,
    required this.trackable,
  });

  final int ingredientId;
  final String name;
  final String unitType;

  /// 재료량 × (계획 인분 ÷ 요리 기준 인분) (D-015)
  final num requiredQuantity;
  final num availableQuantity;
  final num shortageQuantity;

  /// false면 계량 제외 — 예약·부족 판단에서 빠진다 (R-4)
  final bool trackable;

  String get unitLabel => unitLabelOf(unitType);
  bool get isShort => trackable && shortageQuantity.toDouble() > 0;

  factory PreviewIngredient.fromJson(Map<String, dynamic> json) => PreviewIngredient(
        ingredientId: json['ingredientId'] as int,
        name: json['name'] as String? ?? '',
        unitType: json['unitType'] as String? ?? '',
        requiredQuantity: json['requiredQuantity'] as num? ?? 0,
        availableQuantity: json['availableQuantity'] as num? ?? 0,
        shortageQuantity: json['shortageQuantity'] as num? ?? 0,
        trackable: json['trackable'] as bool? ?? true,
      );
}

/// API-41 응답. 아무것도 바꾸지 않는 조회다 (D-010)
class MealPlanPreview {
  MealPlanPreview({
    required this.recipeId,
    required this.recipeName,
    required this.recipeServings,
    required this.servings,
    required this.shortageCount,
    required this.ingredients,
  });

  final int recipeId;
  final String recipeName;

  /// 요리에 등록된 기준 인분 (환산의 분모)
  final int recipeServings;

  /// 이번 계획의 인분
  final int servings;
  final int shortageCount;
  final List<PreviewIngredient> ingredients;

  factory MealPlanPreview.fromJson(Map<String, dynamic> json) => MealPlanPreview(
        recipeId: json['recipeId'] as int,
        recipeName: json['recipeName'] as String? ?? '',
        recipeServings: json['recipeServings'] as int? ?? 1,
        servings: json['servings'] as int? ?? 1,
        shortageCount: json['shortageCount'] as int? ?? 0,
        ingredients: (json['ingredients'] as List<dynamic>? ?? [])
            .map((e) => PreviewIngredient.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// API-42 응답의 재료 한 줄
class MealPlanIngredient {
  MealPlanIngredient({
    required this.ingredientId,
    required this.name,
    required this.unitType,
    required this.requiredQuantity,
    required this.reservedQuantity,
    required this.shortageQuantity,
    required this.trackable,
    required this.addedToShoppingList,
  });

  final int ingredientId;
  final String name;
  final String unitType;
  final num requiredQuantity;

  /// 실제 예약된 양 = min(필요량, 등록 시점 가용량). 취소는 이 값으로 원복한다 (D-025)
  final num reservedQuantity;
  final num shortageQuantity;
  final bool trackable;
  final bool addedToShoppingList;

  factory MealPlanIngredient.fromJson(Map<String, dynamic> json) => MealPlanIngredient(
        ingredientId: json['ingredientId'] as int,
        name: json['name'] as String? ?? '',
        unitType: json['unitType'] as String? ?? '',
        requiredQuantity: json['requiredQuantity'] as num? ?? 0,
        reservedQuantity: json['reservedQuantity'] as num? ?? 0,
        shortageQuantity: json['shortageQuantity'] as num? ?? 0,
        trackable: json['trackable'] as bool? ?? true,
        addedToShoppingList: json['addedToShoppingList'] as bool? ?? false,
      );
}

/// API-42 응답 (계획 상세)
class MealPlanDetail {
  MealPlanDetail({
    required this.id,
    required this.planDate,
    required this.mealType,
    required this.recipeId,
    required this.recipeName,
    required this.servings,
    required this.status,
    required this.ingredients,
  });

  final int id;
  final DateTime planDate;
  final MealType mealType;
  final int recipeId;
  final String recipeName;
  final int servings;
  final MealPlanStatus status;
  final List<MealPlanIngredient> ingredients;

  /// 예약이 잡힌 재료 수 — 등록 직후 안내 문구에 쓴다
  int get reservedCount =>
      ingredients.where((i) => i.reservedQuantity.toDouble() > 0).length;

  int get addedToShoppingCount => ingredients.where((i) => i.addedToShoppingList).length;

  factory MealPlanDetail.fromJson(Map<String, dynamic> json) => MealPlanDetail(
        id: json['id'] as int,
        planDate: parseIsoDate(json['planDate'] as String),
        mealType: MealTypeX.fromCode(json['mealType'] as String?),
        recipeId: json['recipeId'] as int,
        recipeName: json['recipeName'] as String? ?? '',
        servings: json['servings'] as int? ?? 1,
        status: MealPlanStatusX.fromCode(json['status'] as String?),
        ingredients: (json['ingredients'] as List<dynamic>? ?? [])
            .map((e) => MealPlanIngredient.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// API-43 응답
class MealPlanCancelResult {
  MealPlanCancelResult({required this.id, required this.releasedIngredientCount});

  final int id;
  final int releasedIngredientCount;

  factory MealPlanCancelResult.fromJson(Map<String, dynamic> json) => MealPlanCancelResult(
        id: json['id'] as int,
        releasedIngredientCount: json['releasedIngredientCount'] as int? ?? 0,
      );
}
