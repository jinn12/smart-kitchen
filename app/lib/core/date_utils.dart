// 날짜 표기. 서버의 LocalDate는 "2026-08-21" 문자열로 오간다.
// intl 패키지를 들이는 대신 필요한 표기만 직접 만든다 — 한국어 고정이라 규칙이 단순하다.

const _weekdayNames = ['월', '화', '수', '목', '금', '토', '일'];

/// 시각을 버린 오늘 (날짜 비교용)
DateTime today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

/// 2026-08-21
String toIsoDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

DateTime parseIsoDate(String raw) => DateTime.parse(raw);

/// 8월 21일 (금)
String formatDayLabel(DateTime date) =>
    '${date.month}월 ${date.day}일 (${_weekdayNames[date.weekday - 1]})';

/// 8월 21일 — 기간 표기용(요일 없이)
String formatShortDate(DateTime date) => '${date.month}월 ${date.day}일';

/// 오늘·내일은 이름으로 부르는 편이 읽기 쉽다
String? relativeDayLabel(DateTime date) {
  final diff = date.difference(today()).inDays;
  return switch (diff) {
    0 => '오늘',
    1 => '내일',
    _ => null,
  };
}

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
