import '../../core/api_client.dart';
import '../../core/api_exception.dart';
import 'shopping_models.dart';

class ShoppingApi {
  ShoppingApi(this._client);

  final ApiClient _client;

  /// API-50. 미체크 먼저, 그 안에서 이름순으로 온다
  Future<ShoppingList> list() {
    return callApi(() async {
      final res = await _client.dio.get('/shopping-list');
      return ShoppingList.fromJson(res.data as Map<String, dynamic>);
    }, fallback: '장보기 목록을 불러오지 못했습니다');
  }

  /// API-51. 같은 재료가 있으면 서버가 수량을 가산하고 체크를 푼다 (D-025)
  Future<ShoppingList> addItem({required int ingredientId, required num quantity}) {
    return callApi(() async {
      final res = await _client.dio.post('/shopping-list/items', data: {
        'ingredientId': ingredientId,
        'quantity': quantity,
      });
      return ShoppingList.fromJson(res.data as Map<String, dynamic>);
    }, fallback: '항목을 담지 못했습니다');
  }

  /// API-52. 온 필드만 반영된다
  Future<ShoppingItem> updateItem(int id, {bool? isChecked, num? quantity}) {
    return callApi(() async {
      final res = await _client.dio.patch('/shopping-list/items/$id', data: {
        'isChecked': ?isChecked,
        'quantity': ?quantity,
      });
      return ShoppingItem.fromJson(res.data as Map<String, dynamic>);
    }, fallback: '항목을 수정하지 못했습니다');
  }

  /// API-54. 물리 삭제 (D-026)
  Future<void> deleteItem(int id) {
    return callApi(() async {
      await _client.dio.delete('/shopping-list/items/$id');
    }, fallback: '항목을 삭제하지 못했습니다');
  }

  /// API-53. 체크된 항목을 재고로 옮긴다 — 순환의 마지막 연결
  Future<ShoppingCompleteResult> complete() {
    return callApi(() async {
      final res = await _client.dio.post('/shopping-list/complete');
      return ShoppingCompleteResult.fromJson(res.data as Map<String, dynamic>);
    }, fallback: '구매 완료 처리를 하지 못했습니다');
  }
}
