import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen/core/api_exception.dart';

/// 오류 문구 변환. 서버 공통 오류(D-028)와 네트워크 상황을 갈라 쓴다.
void main() {
  final options = RequestOptions(path: '/recipes');

  test('시간 초과는 재시도를 권하는 문구로 바꾼다', () {
    for (final type in [
      DioExceptionType.connectionTimeout,
      DioExceptionType.receiveTimeout,
      DioExceptionType.sendTimeout,
    ]) {
      final e = ApiException.from(DioException(requestOptions: options, type: type));
      expect(e.message, '서버 응답이 지연되고 있습니다. 잠시 후 다시 시도해주세요',
          reason: '$type');
    }
  });

  test('연결 자체가 안 되면 시간 초과와 다른 문구를 쓴다', () {
    final e = ApiException.from(DioException(
      requestOptions: options,
      type: DioExceptionType.connectionError,
    ));
    expect(e.message, '서버에 연결할 수 없습니다');
  });

  test('서버가 준 message를 그대로 보여준다 (D-028)', () {
    final e = ApiException.from(DioException(
      requestOptions: options,
      type: DioExceptionType.badResponse,
      response: Response(
        requestOptions: options,
        statusCode: 400,
        data: {'status': 400, 'message': '같은 재료를 두 번 넣을 수 없습니다'},
      ),
    ));
    expect(e.message, '같은 재료를 두 번 넣을 수 없습니다');
    expect(e.status, 400);
  });
}
