import '../../core/api_client.dart';
import '../../core/api_exception.dart';
import '../../core/token_storage.dart';

class AuthApi {
  AuthApi(this._client, this._tokenStorage);

  final ApiClient _client;
  final TokenStorage _tokenStorage;

  /// API-02. 성공 시 토큰을 저장하고 닉네임을 돌려준다.
  Future<String> login(String email, String password) {
    return callApi(() async {
      final res = await _client.dio.post('/auth/login',
          data: {'email': email, 'password': password});
      final token = res.data['accessToken'] as String;
      final nickname = res.data['nickname'] as String?;
      await _tokenStorage.save(token);
      // 설정 화면에서 쓸 계정 정보. 서버에 조회 API가 없어 이때 받은 값을 남겨둔다
      await _tokenStorage.saveAccount(email: email, nickname: nickname);
      return nickname ?? email;
    }, fallback: '로그인에 실패했습니다');
  }

  /// API-01. 가입만 하고 토큰은 주지 않는다 — 호출부에서 login을 이어서 부른다.
  Future<void> signup(String email, String password, String? nickname) {
    return callApi(() async {
      await _client.dio.post('/auth/signup', data: {
        'email': email,
        'password': password,
        if (nickname != null && nickname.isNotEmpty) 'nickname': nickname,
      });
    }, fallback: '회원가입에 실패했습니다');
  }
}
