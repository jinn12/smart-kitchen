import 'package:dio/dio.dart';
import 'token_storage.dart';

class ApiClient {
  ApiClient(this._tokenStorage) {
    dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080/api'));
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
