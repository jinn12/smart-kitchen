import 'package:dio/dio.dart';

/// 백엔드 공통 오류 응답을 사용자에게 보여줄 메시지로 바꾼다.
///
/// 서버는 모든 오류를 아래 형태로 준다.
/// { timestamp, status, error, message, path }
class ApiException implements Exception {
  ApiException(this.message, {this.status});

  final String message;
  final int? status;

  /// DioException에서 공통 오류 본문의 message를 꺼낸다.
  /// 본문이 없거나 형식이 다르면(네트워크 끊김 등) 상황에 맞는 기본 문구를 쓴다.
  factory ApiException.from(DioException e, {String fallback = '요청을 처리하지 못했습니다'}) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String) {
      return ApiException(data['message'] as String, status: e.response?.statusCode);
    }
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return ApiException('서버에 연결할 수 없습니다');
    }
    return ApiException(fallback, status: e.response?.statusCode);
  }

  @override
  String toString() => message;
}

/// API 호출을 감싸 DioException을 ApiException으로 바꾼다.
/// 각 API 클래스에서 try/catch를 반복하지 않기 위한 헬퍼.
Future<T> callApi<T>(Future<T> Function() request, {String fallback = '요청을 처리하지 못했습니다'}) async {
  try {
    return await request();
  } on DioException catch (e) {
    throw ApiException.from(e, fallback: fallback);
  }
}
