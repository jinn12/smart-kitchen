import '../../core/api_client.dart';
import '../../core/api_exception.dart';
import 'inventory_models.dart';

class InventoryApi {
  InventoryApi(this._client);

  final ApiClient _client;

  /// API-20. storageLocation이 null이면 전체
  Future<List<InventoryItemSummary>> list({StorageLocation? storage}) {
    return callApi(() async {
      final res = await _client.dio.get('/inventories', queryParameters: {
        if (storage != null) 'storageLocation': storage.code,
      });
      return (res.data as List<dynamic>)
          .map((e) => InventoryItemSummary.fromJson(e as Map<String, dynamic>))
          .toList();
    }, fallback: '재고를 불러오지 못했습니다');
  }

  /// API-24. 임박·만료만 (dday 오름차순)
  Future<List<InventoryItemSummary>> expiring() {
    return callApi(() async {
      final res = await _client.dio.get('/inventories/expiring');
      return (res.data as List<dynamic>)
          .map((e) => InventoryItemSummary.fromJson(e as Map<String, dynamic>))
          .toList();
    }, fallback: '임박 재고를 불러오지 못했습니다');
  }

  /// API-22
  Future<InventoryDetail> detail(int ingredientId) {
    return callApi(() async {
      final res = await _client.dio.get('/inventories/$ingredientId');
      return InventoryDetail.fromJson(res.data as Map<String, dynamic>);
    }, fallback: '재고 상세를 불러오지 못했습니다');
  }

  /// API-21. 여러 재료를 한 번에 등록한다 (S-13)
  Future<void> addItems(List<({int ingredientId, num quantity})> items) {
    return callApi(() async {
      await _client.dio.post('/inventories/items',
          data: items
              .map((e) => {'ingredientId': e.ingredientId, 'quantity': e.quantity})
              .toList());
    }, fallback: '재고 등록에 실패했습니다');
  }

  /// API-23. ADJUST만 quantity가 필요하다
  Future<void> updateBatch(int batchId, String action, {num? quantity}) {
    return callApi(() async {
      await _client.dio.patch('/inventories/items/$batchId', data: {
        'action': action,
        'quantity': ?quantity,
      });
    }, fallback: '배치를 처리하지 못했습니다');
  }

  /// API-25. 해당 재료의 배치 전체가 함께 옮겨진다
  Future<void> changeStorage(int ingredientId, StorageLocation storage) {
    return callApi(() async {
      await _client.dio.patch('/inventories/$ingredientId',
          data: {'storageLocation': storage.code});
    }, fallback: '보관 장소를 바꾸지 못했습니다');
  }

  /// API-10. S-13의 재료 검색
  Future<List<IngredientSearchResult>> searchIngredients({
    String? keyword,
    String? category,
  }) {
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
