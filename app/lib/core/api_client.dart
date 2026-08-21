import 'package:dio/dio.dart';
import 'token_storage.dart';

class ApiClient {
  ApiClient(this._tokenStorage) {
    dio = Dio(BaseOptions(
      baseUrl: 'http://localhost:8080/api',
      // 서버가 죽었거나 네트워크가 막히면 무한 대기 대신 5초 만에 끊는다.
      connectTimeout: const Duration(seconds: 5),
      // 응답은 넉넉히 준다 — 레시피 검색(API-33)처럼 1,100여 건을 훑는 조회가 있다.
      receiveTimeout: const Duration(seconds: 15),
    ));
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _tokenStorage.read();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (e, handler) async {
        // 토큰 만료·위조는 서버가 401로 준다. 저장된 토큰을 버리고 로그인 화면으로 돌린다.
        // 로그인·가입 자체의 401(비밀번호 불일치)은 화면에서 메시지로 보여줘야 하므로 제외한다.
        final path = e.requestOptions.path;
        final isAuthRequest = path.startsWith('/auth/');
        if (e.response?.statusCode == 401 && !isAuthRequest) {
          await _tokenStorage.clear();
          onUnauthorized?.call();
        }
        handler.next(e);
      },
    ));
  }

  final TokenStorage _tokenStorage;
  late final Dio dio;

  /// 401을 받았을 때 앱이 로그인 상태를 내리도록 main에서 연결한다.
  void Function()? onUnauthorized;
}
