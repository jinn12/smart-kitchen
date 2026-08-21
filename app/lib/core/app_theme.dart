import 'package:flutter/material.dart';

/// 브랜드 시드 — 딥 티얼. 주방·신선함 쪽 톤이면서 식재료 사진과 부딪히지 않는다.
const seedColor = Color(0xFF00796B);

/// 상태를 뜻하는 색. 시드에서 파생하지 않고 고정값으로 둔다 —
/// "만료/임박/확보"는 브랜드 색이 바뀌어도 같은 의미로 읽혀야 하고,
/// 도메인 규칙(R-5·D-020·D-024)에 묶여 있어 화면마다 달라지면 안 된다.
abstract final class StatusColors {
  /// 만료·부족 (D-020 만료 배지, sufficient=false, 부족 수량)
  /// M3의 기본 error와 같은 값이라 colorScheme.error와 나란히 놓여도 어긋나지 않는다.
  static const expired = Color(0xFFBA1A1A);

  /// 임박 (D-3~D-0, R-5). 당일도 만료가 아니라 임박이다
  static const expiring = Color(0xFFA15C00);

  /// 확보·지금 가능 (cookableNow, sufficient=true, 입고)
  static const secured = Color(0xFF1B5E20);
}

/// 앱 테마. 곡률과 여백을 기본값보다 한 단계 부드럽게 잡아 화면 전체의 인상을 눅인다.
ThemeData buildAppTheme() {
  final base = ThemeData(
    colorSchemeSeed: seedColor,
    useMaterial3: true,
    fontFamily: 'Pretendard',
  );

  return base.copyWith(
    cardTheme: const CardThemeData(
      // M3 기본 12 -> 16
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
      clipBehavior: Clip.antiAlias,
    ),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      minVerticalPadding: 8,
    ),
    dialogTheme: const DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
    ),
    inputDecorationTheme: const InputDecorationThemeData(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
  );
}
