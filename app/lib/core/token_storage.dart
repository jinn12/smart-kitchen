import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 로그인 세션 보관소. 토큰과, 설정 화면(S-51)에 보여줄 계정 정보를 함께 갖는다.
///
/// 계정 정보를 로컬에 두는 이유: 서버에 "내 정보" 조회 API가 없고 JWT에도 userId만 들어 있어
/// 앱 재시작 후에는 이메일·닉네임을 알 방법이 없다. 로그인 시 받은 값을 그대로 보관한다.
class TokenStorage {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'accessToken';
  static const _emailKey = 'accountEmail';
  static const _nicknameKey = 'accountNickname';

  Future<void> save(String token) => _storage.write(key: _tokenKey, value: token);
  Future<String?> read() => _storage.read(key: _tokenKey);

  Future<void> saveAccount({required String email, String? nickname}) async {
    await _storage.write(key: _emailKey, value: email);
    await _storage.write(key: _nicknameKey, value: nickname);
  }

  Future<({String? email, String? nickname})> readAccount() async {
    return (
      email: await _storage.read(key: _emailKey),
      nickname: await _storage.read(key: _nicknameKey),
    );
  }

  /// 로그아웃·세션 만료 시 토큰과 계정 정보를 함께 지운다
  Future<void> clear() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _emailKey);
    await _storage.delete(key: _nicknameKey);
  }
}
