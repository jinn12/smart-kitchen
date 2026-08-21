import 'package:flutter/foundation.dart';
import '../../core/token_storage.dart';
import 'auth_api.dart';

/// 로그인 상태. 앱 루트가 이 값을 보고 로그인 화면과 메인 셸을 가른다.
class AuthState extends ChangeNotifier {
  AuthState(this._authApi, this._tokenStorage);

  final AuthApi _authApi;
  final TokenStorage _tokenStorage;

  bool _initializing = true;
  bool _loggedIn = false;
  String? _nickname;
  String? _email;

  bool get initializing => _initializing;
  bool get loggedIn => _loggedIn;
  String? get nickname => _nickname;

  /// 설정 화면(S-51) 표시용. 로그인 시점에 저장해 둔 값이다 — 서버 조회가 아니다
  String? get email => _email;

  /// 앱 시작 시 저장된 토큰을 확인한다. 있으면 바로 메인으로 보낸다.
  /// 토큰이 실제로 유효한지는 첫 API 호출에서 판가름나고, 만료라면 401 인터셉터가 로그아웃시킨다.
  Future<void> restore() async {
    final token = await _tokenStorage.read();
    _loggedIn = token != null;
    if (_loggedIn) {
      final account = await _tokenStorage.readAccount();
      _email = account.email;
      _nickname = account.nickname;
    }
    _initializing = false;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    _nickname = await _authApi.login(email, password);
    _email = email;
    _loggedIn = true;
    notifyListeners();
  }

  /// 가입 후 곧바로 로그인까지 이어서 메인으로 진입시킨다 (S-02)
  Future<void> signup(String email, String password, String? nickname) async {
    await _authApi.signup(email, password, nickname);
    await login(email, password);
  }

  Future<void> logout() async {
    await _tokenStorage.clear();
    _loggedIn = false;
    _nickname = null;
    _email = null;
    notifyListeners();
  }

  /// 401 인터셉터가 부른다. 토큰은 이미 지워진 상태다.
  void onSessionExpired() {
    if (!_loggedIn) return;
    _loggedIn = false;
    _nickname = null;
    _email = null;
    notifyListeners();
  }
}
