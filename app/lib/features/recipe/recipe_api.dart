import '../../core/api_client.dart';
import '../../core/api_exception.dart';
import 'recipe_models.dart';

class RecipeApi {
  RecipeApi(this._client);

  final ApiClient _client;

  /// API-30. household 스코프, 이름 오름차순
  Future<List<RecipeSummary>> list() {
    return callApi(() async {
      final res = await _client.dio.get('/recipes');
      return (res.data as List<dynamic>)
          .map((e) => RecipeSummary.fromJson(e as Map<String, dynamic>))
          .toList();
    }, fallback: '요리 목록을 불러오지 못했습니다');
  }

  /// API-32
  Future<RecipeDetail> detail(int id) {
    return callApi(() async {
      final res = await _client.dio.get('/recipes/$id');
      return RecipeDetail.fromJson(res.data as Map<String, dynamic>);
    }, fallback: '요리 상세를 불러오지 못했습니다');
  }

  /// API-31. MANUAL은 name이, MASTER는 recipeMasterId가 필수다.
  /// ingredients는 사용자가 확정한 최종 목록 (D-007)
  Future<RecipeDetail> create({
    required RecipeSource source,
    String? name,
    int? recipeMasterId,
    required int servings,
    required List<({int ingredientId, num quantity})> ingredients,
  }) {
    return callApi(() async {
      final res = await _client.dio.post('/recipes', data: {
        'source': source.code,
        'name': ?name,
        'recipeMasterId': ?recipeMasterId,
        'servings': servings,
        'ingredients': ingredients
            .map((e) => {'ingredientId': e.ingredientId, 'quantity': e.quantity})
            .toList(),
      });
      return RecipeDetail.fromJson(res.data as Map<String, dynamic>);
    }, fallback: '요리를 등록하지 못했습니다');
  }

  /// API-33. 공공 레시피 검색 (페이징)
  Future<RecipeMasterPage> searchMasters({
    String? keyword,
    String? category,
    int page = 0,
    int size = 20,
  }) {
    return callApi(() async {
      final res = await _client.dio.get('/recipe-masters', queryParameters: {
        if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
        if (category != null && category.isNotEmpty) 'category': category,
        'page': page,
        'size': size,
      });
      return RecipeMasterPage.fromJson(res.data as Map<String, dynamic>);
    }, fallback: '레시피를 검색하지 못했습니다');
  }

  /// API-34. 매핑 확인 화면의 원본
  Future<RecipeMasterDetail> masterDetail(int id) {
    return callApi(() async {
      final res = await _client.dio.get('/recipe-masters/$id');
      return RecipeMasterDetail.fromJson(res.data as Map<String, dynamic>);
    }, fallback: '레시피를 불러오지 못했습니다');
  }
}
