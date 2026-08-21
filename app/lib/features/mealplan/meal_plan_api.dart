import '../../core/api_client.dart';
import '../../core/api_exception.dart';
import '../../core/date_utils.dart';
import 'meal_plan_models.dart';

class MealPlanApi {
  MealPlanApi(this._client);

  final ApiClient _client;

  /// API-40. 기간 내 모든 날짜가 오고, 계획 없는 날은 meals가 빈 배열이다
  Future<List<MealPlanDay>> weekly({required DateTime from, required DateTime to}) {
    return callApi(() async {
      final res = await _client.dio.get('/meal-plans', queryParameters: {
        'from': toIsoDate(from),
        'to': toIsoDate(to),
      });
      return (res.data as List<dynamic>)
          .map((e) => MealPlanDay.fromJson(e as Map<String, dynamic>))
          .toList();
    }, fallback: '식탁을 불러오지 못했습니다');
  }

  /// API-41. 조회 전용 — 아무것도 예약하지 않는다 (D-010)
  Future<MealPlanPreview> preview({required int recipeId, required int servings}) {
    return callApi(() async {
      final res = await _client.dio.post('/meal-plans/preview', data: {
        'recipeId': recipeId,
        'servings': servings,
      });
      return MealPlanPreview.fromJson(res.data as Map<String, dynamic>);
    }, fallback: '부족 재료를 확인하지 못했습니다');
  }

  /// API-42. 여기서부터 재고가 예약된다 (R-1)
  Future<MealPlanDetail> create({
    required int recipeId,
    required DateTime planDate,
    required MealType mealType,
    required int servings,
    required List<int> addToShoppingIngredientIds,
  }) {
    return callApi(() async {
      final res = await _client.dio.post('/meal-plans', data: {
        'recipeId': recipeId,
        'planDate': toIsoDate(planDate),
        'mealType': mealType.code,
        'servings': servings,
        'addToShoppingIngredientIds': addToShoppingIngredientIds,
      });
      return MealPlanDetail.fromJson(res.data as Map<String, dynamic>);
    }, fallback: '계획을 등록하지 못했습니다');
  }

  /// API-43. 예약 스냅샷만큼 원복한다 (D-025)
  Future<MealPlanCancelResult> cancel(int id) {
    return callApi(() async {
      final res = await _client.dio.delete('/meal-plans/$id');
      return MealPlanCancelResult.fromJson(res.data as Map<String, dynamic>);
    }, fallback: '계획을 취소하지 못했습니다');
  }
}
