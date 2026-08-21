import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smart_kitchen/core/api_client.dart';
import 'package:smart_kitchen/core/app_info.dart';
import 'package:smart_kitchen/core/token_storage.dart';
import 'package:smart_kitchen/features/auth/auth_api.dart';
import 'package:smart_kitchen/features/auth/auth_state.dart';
import 'package:smart_kitchen/features/settings/settings_screen.dart';

/// 계정 정보는 로그인 시점에 저장해 둔 값을 그대로 보여준다 (서버 조회 API 없음).
class _FakeAuthState extends AuthState {
  _FakeAuthState({this.fakeEmail, this.fakeNickname})
      : super(AuthApi(ApiClient(TokenStorage()), TokenStorage()), TokenStorage());

  final String? fakeEmail;
  final String? fakeNickname;
  bool loggedOut = false;

  @override
  String? get email => fakeEmail;

  @override
  String? get nickname => fakeNickname;

  @override
  Future<void> logout() async => loggedOut = true;
}

void main() {
  Future<void> pump(WidgetTester tester, _FakeAuthState auth) {
    return tester.pumpWidget(
      ChangeNotifierProvider<AuthState>.value(
        value: auth,
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
  }

  testWidgets('계정 정보와 앱 정보를 보여준다', (tester) async {
    await pump(tester, _FakeAuthState(fakeEmail: 'jinny@example.com', fakeNickname: '유진'));

    expect(find.text('jinny@example.com'), findsOneWidget);
    expect(find.text('유진'), findsOneWidget);
    expect(find.text(appVersion), findsOneWidget);
    // 공공데이터 이용 조건상 출처를 밝혀야 한다
    expect(find.textContaining('식품의약품안전처'), findsWidgets);
    expect(find.text('개인정보처리방침'), findsOneWidget);
  });

  testWidgets('저장된 계정 정보가 없으면 -로 둔다', (tester) async {
    await pump(tester, _FakeAuthState());
    expect(find.text('-'), findsNWidgets(2));
  });

  testWidgets('로그아웃은 확인을 받고 실행한다', (tester) async {
    final auth = _FakeAuthState(fakeEmail: 'jinny@example.com', fakeNickname: '유진');
    await pump(tester, auth);

    await tester.tap(find.text('로그아웃'));
    await tester.pumpAndSettle();
    expect(find.textContaining('다시 이용하려면'), findsOneWidget);
    expect(auth.loggedOut, isFalse, reason: '확인 전에는 로그아웃하지 않는다');

    await tester.tap(find.widgetWithText(TextButton, '닫기'));
    await tester.pumpAndSettle();
    expect(auth.loggedOut, isFalse);

    await tester.tap(find.text('로그아웃'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '로그아웃'));
    await tester.pumpAndSettle();
    expect(auth.loggedOut, isTrue);
  });
}
