import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen/core/app_theme.dart';
import 'package:smart_kitchen/features/inventory/expiry_badge.dart';
import 'package:smart_kitchen/features/inventory/inventory_models.dart';

/// 테마와 의미색. 의미색은 시안에서 확정된 값이라 코드가 단일 출처다.
void main() {
  test('시드 컬러와 본문 폰트', () {
    final theme = buildAppTheme();
    expect(seedColor, const Color(0xFF00796B));
    expect(theme.textTheme.bodyMedium?.fontFamily, 'Pretendard');
  });

  test('상태색은 브랜드 색과 무관하게 고정값이다', () {
    expect(StatusColors.expired, const Color(0xFFBA1A1A));
    expect(StatusColors.expiring, const Color(0xFFA15C00));
    expect(StatusColors.secured, const Color(0xFF1B5E20));
  });

  test('만료색은 M3 error와 같은 값이라 나란히 놓여도 어긋나지 않는다', () {
    expect(buildAppTheme().colorScheme.error, StatusColors.expired);
  });

  testWidgets('유통기한 배지가 의미색 상수를 쓴다 (R-5, D-020)', (tester) async {
    Future<Color?> colorOf(ExpiryStatus status, int? dday) async {
      await tester.pumpWidget(MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(body: ExpiryBadge(status: status, dday: dday)),
      ));
      final text = tester.widget<Text>(find.byType(Text));
      return text.style?.color;
    }

    expect(await colorOf(ExpiryStatus.expired, -1), StatusColors.expired);
    // 당일(D-0)도 만료가 아니라 임박이다
    expect(await colorOf(ExpiryStatus.expiring, 0), StatusColors.expiring);
  });
}
