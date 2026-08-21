import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen/core/empty_state.dart';

/// 빈 화면이 곧 첫 사용 안내다 — 설명만 두지 않고 다음 행동을 준다.
void main() {
  Future<void> pump(WidgetTester tester, Widget child) {
    return tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
  }

  testWidgets('제목·설명과 함께 행동 버튼을 보여준다', (tester) async {
    var tapped = false;
    await pump(
      tester,
      EmptyState(
        icon: Icons.kitchen_outlined,
        title: '장 봐온 재료를 등록해보세요',
        description: '재료를 넣어두면 요리·식단·장보기가 자동으로 이어져요.',
        actionLabel: '재료 등록하기',
        onAction: () => tapped = true,
      ),
    );

    expect(find.text('장 봐온 재료를 등록해보세요'), findsOneWidget);
    expect(find.text('재료를 넣어두면 요리·식단·장보기가 자동으로 이어져요.'), findsOneWidget);

    await tester.tap(find.text('재료 등록하기'));
    expect(tapped, isTrue);
  });

  testWidgets('할 행동이 없으면 버튼을 만들지 않는다', (tester) async {
    await pump(
      tester,
      const EmptyState(
        icon: Icons.search_off,
        title: '검색 결과가 없어요',
        description: '다른 이름으로 찾아보세요.',
      ),
    );

    expect(find.text('검색 결과가 없어요'), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
  });
}
