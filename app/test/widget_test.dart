import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen/features/inventory/expiry_badge.dart';
import 'package:smart_kitchen/features/inventory/inventory_models.dart';

/// D-배지 표기 규칙 (R-5, D-020) — 당일(dday=0)은 만료가 아니라 임박이다.
void main() {
  Future<void> pumpBadge(WidgetTester tester, ExpiryStatus status, int? dday) {
    return tester.pumpWidget(MaterialApp(
      home: Scaffold(body: ExpiryBadge(status: status, dday: dday)),
    ));
  }

  testWidgets('유통기한이 지나면 만료로 표시한다', (tester) async {
    await pumpBadge(tester, ExpiryStatus.expired, -1);
    expect(find.text('만료'), findsOneWidget);
  });

  testWidgets('임박은 D-n으로 표시한다', (tester) async {
    await pumpBadge(tester, ExpiryStatus.expiring, 3);
    expect(find.text('D-3'), findsOneWidget);
  });

  testWidgets('유통기한 당일도 임박(D-0)으로 표시한다', (tester) async {
    await pumpBadge(tester, ExpiryStatus.expiring, 0);
    expect(find.text('D-0'), findsOneWidget);
    expect(find.text('만료'), findsNothing);
  });

  testWidgets('유통기한 배치가 없으면 없음으로 표시한다', (tester) async {
    await pumpBadge(tester, ExpiryStatus.none, null);
    expect(find.text('유통기한 없음'), findsOneWidget);
  });
}
