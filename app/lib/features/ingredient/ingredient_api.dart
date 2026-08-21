import '../../core/api_client.dart';
import '../../core/api_exception.dart';
import 'ingredient_models.dart';

/// 식재료 검색 (API-10). 재고·요리·장보기가 함께 쓰는 공용 API라
/// 특정 도메인 API 클래스가 아니라 여기에 둔다.
class IngredientApi {
  IngredientApi(this._client);

  final ApiClient _client;

  /// API-10. 마스터 + 내 커스텀, 이름 오름차순.
  /// keyword·category가 비어 있으면 미지정과 같다
  Future<List<IngredientSearchResult>> search({String? keyword, String? category}) {
    return callApi(() async {
      final res = await _client.dio.get('/ingredients', queryParameters: {
        if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
        if (category != null && category.isNotEmpty) 'category': category,
      });
      return (res.data as List<dynamic>)
          .map((e) => IngredientSearchResult.fromJson(e as Map<String, dynamic>))
          .toList();
    }, fallback: '식재료를 불러오지 못했습니다');
  }
}
