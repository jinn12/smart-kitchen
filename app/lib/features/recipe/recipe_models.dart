// 요리 도메인 모델. 서버 응답(API-30~34)을 그대로 옮긴다.

import '../ingredient/ingredient_models.dart' show unitLabelOf;

/// 요리 출처. MASTER는 공공 레시피에서 복제한 것 (D-014)
enum RecipeSource { manual, master }

extension RecipeSourceX on RecipeSource {
  String get code => switch (this) {
        RecipeSource.manual => 'MANUAL',
        RecipeSource.master => 'MASTER',
      };

  String get label => switch (this) {
        RecipeSource.manual => '직접 입력',
        RecipeSource.master => '레시피',
      };

  static RecipeSource fromCode(String? code) =>
      code == 'MASTER' ? RecipeSource.master : RecipeSource.manual;
}

/// 공공 레시피의 카테고리 6종 (API-33). 식재료 13종(D-017)과는 다른 축이다.
const recipeMasterCategories = <String>['밥', '국&찌개', '반찬', '일품', '후식', '기타'];

/// API-30 내 요리 목록 한 건
class RecipeSummary {
  RecipeSummary({
    required this.id,
    required this.name,
    required this.servings,
    required this.source,
    required this.ingredientCount,
    required this.cookableNow,
  });

  final int id;
  final String name;
  final int servings;
  final RecipeSource source;
  final int ingredientCount;

  /// 등록한 분량 그대로 지금 만들 수 있는가 (D-024). 인분 환산이 아니다
  final bool cookableNow;

  factory RecipeSummary.fromJson(Map<String, dynamic> json) => RecipeSummary(
        id: json['id'] as int,
        name: json['name'] as String,
        servings: json['servings'] as int? ?? 1,
        source: RecipeSourceX.fromCode(json['source'] as String?),
        ingredientCount: json['ingredientCount'] as int? ?? 0,
        cookableNow: json['cookableNow'] as bool? ?? false,
      );
}

/// API-32 상세의 재료 한 줄
class RecipeIngredient {
  RecipeIngredient({
    required this.ingredientId,
    required this.name,
    required this.quantity,
    required this.unitType,
    required this.availableQuantity,
    required this.sufficient,
  });

  final int ingredientId;
  final String name;
  final num quantity;
  final String unitType;
  final num availableQuantity;

  /// 잔량 관리를 하지 않는 재료(R-4)는 판단 자체를 하지 않아 null이다
  final bool? sufficient;

  String get unitLabel => unitLabelOf(unitType);

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) => RecipeIngredient(
        ingredientId: json['ingredientId'] as int,
        name: json['name'] as String,
        quantity: json['quantity'] as num? ?? 0,
        unitType: json['unitType'] as String? ?? '',
        availableQuantity: json['availableQuantity'] as num? ?? 0,
        sufficient: json['sufficient'] as bool?,
      );
}

/// API-32 내 요리 상세
class RecipeDetail {
  RecipeDetail({
    required this.id,
    required this.name,
    required this.servings,
    required this.source,
    required this.recipeMasterId,
    required this.cookableNow,
    required this.ingredients,
  });

  final int id;
  final String name;
  final int servings;
  final RecipeSource source;
  final int? recipeMasterId;
  final bool cookableNow;
  final List<RecipeIngredient> ingredients;

  factory RecipeDetail.fromJson(Map<String, dynamic> json) => RecipeDetail(
        id: json['id'] as int,
        name: json['name'] as String,
        servings: json['servings'] as int? ?? 1,
        source: RecipeSourceX.fromCode(json['source'] as String?),
        recipeMasterId: json['recipeMasterId'] as int?,
        cookableNow: json['cookableNow'] as bool? ?? false,
        ingredients: (json['ingredients'] as List<dynamic>? ?? [])
            .map((e) => RecipeIngredient.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// API-33 검색 결과 한 건
class RecipeMasterSummary {
  RecipeMasterSummary({
    required this.id,
    required this.name,
    required this.category,
    required this.cookWay,
    required this.imageUrl,
    required this.kcal1p,
  });

  final int id;
  final String name;
  final String category;
  final String? cookWay;
  final String? imageUrl;
  final num? kcal1p;

  factory RecipeMasterSummary.fromJson(Map<String, dynamic> json) => RecipeMasterSummary(
        id: json['id'] as int,
        name: json['name'] as String,
        category: json['category'] as String? ?? '',
        cookWay: json['cookWay'] as String?,
        imageUrl: json['imageUrl'] as String?,
        kcal1p: json['kcal1p'] as num?,
      );
}

/// API-33 페이징 응답
class RecipeMasterPage {
  RecipeMasterPage({
    required this.totalCount,
    required this.page,
    required this.size,
    required this.items,
  });

  final int totalCount;
  final int page;
  final int size;
  final List<RecipeMasterSummary> items;

  factory RecipeMasterPage.fromJson(Map<String, dynamic> json) => RecipeMasterPage(
        totalCount: (json['totalCount'] as num? ?? 0).toInt(),
        page: json['page'] as int? ?? 0,
        size: json['size'] as int? ?? 20,
        items: (json['items'] as List<dynamic>? ?? [])
            .map((e) => RecipeMasterSummary.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// 배치 매핑이 찾아낸 우리 식재료 (API-34)
class MatchedIngredient {
  const MatchedIngredient({required this.id, required this.name, required this.unitType});

  final int id;
  final String name;
  final String unitType;

  String get unitLabel => unitLabelOf(unitType);

  factory MatchedIngredient.fromJson(Map<String, dynamic> json) => MatchedIngredient(
        id: json['id'] as int,
        name: json['name'] as String,
        unitType: json['unitType'] as String? ?? '',
      );
}

/// API-34 마스터 재료 한 줄. matchedIngredient가 null이면 사용자 지정 대상 (D-007)
class RecipeMasterIngredient {
  RecipeMasterIngredient({
    required this.rawText,
    required this.parsedName,
    required this.parsedQty,
    required this.parsedUnit,
    required this.matched,
  });

  final String rawText;
  final String parsedName;
  final num? parsedQty;
  final String? parsedUnit;
  final MatchedIngredient? matched;

  factory RecipeMasterIngredient.fromJson(Map<String, dynamic> json) => RecipeMasterIngredient(
        rawText: json['rawText'] as String? ?? '',
        parsedName: json['parsedName'] as String? ?? '',
        parsedQty: json['parsedQty'] as num?,
        parsedUnit: json['parsedUnit'] as String?,
        matched: json['matchedIngredient'] == null
            ? null
            : MatchedIngredient.fromJson(json['matchedIngredient'] as Map<String, dynamic>),
      );
}

/// API-34 마스터 상세 = 재료 매핑 확인 화면의 원본
class RecipeMasterDetail {
  RecipeMasterDetail({
    required this.id,
    required this.name,
    required this.category,
    required this.cookWay,
    required this.imageUrl,
    required this.kcal1p,
    required this.servings,
    required this.ingredients,
  });

  final int id;
  final String name;
  final String category;
  final String? cookWay;
  final String? imageUrl;
  final num? kcal1p;

  /// 공공 레시피는 항상 1인분 기준이다 (D-015)
  final int servings;
  final List<RecipeMasterIngredient> ingredients;

  factory RecipeMasterDetail.fromJson(Map<String, dynamic> json) => RecipeMasterDetail(
        id: json['id'] as int,
        name: json['name'] as String,
        category: json['category'] as String? ?? '',
        cookWay: json['cookWay'] as String?,
        imageUrl: json['imageUrl'] as String?,
        kcal1p: json['kcal1p'] as num?,
        servings: json['servings'] as int? ?? 1,
        ingredients: (json['ingredients'] as List<dynamic>? ?? [])
            .map((e) => RecipeMasterIngredient.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// 원문 단위(g/ml/개…)가 우리 식재료의 base_unit과 같은 축인지 (D-004).
///
/// 다르면 숫자를 그대로 쓸 수 없다 — "새송이버섯 1개"를 WEIGHT 재료에 1g으로 넣으면 거짓말이 된다.
/// 이 경우 수량을 비워 두고 사용자가 확인하게 한다.
bool unitMatchesBaseUnit(String? parsedUnit, String unitType) {
  if (parsedUnit == null) return false;
  return parsedUnit.trim() == unitLabelOf(unitType);
}
