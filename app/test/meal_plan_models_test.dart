import 'package:flutter_test/flutter_test.dart';
import 'package:smart_kitchen/core/date_utils.dart';
import 'package:smart_kitchen/features/mealplan/meal_plan_models.dart';

/// 식사 계획 표시 규칙 (R-1·R-4·R-6, D-010)
void main() {
  group('주간 식탁 (API-40)', () {
    test('확정된 계획은 취소할 수 없다 (R-6 — 이미 차감이 끝났다)', () {
      final planned = MealSummary.fromJson(
          {'id': 1, 'mealType': 'DINNER', 'recipeName': '된장찌개', 'servings': 2, 'status': 'PLANNED'});
      final confirmed = MealSummary.fromJson(
          {'id': 2, 'mealType': 'LUNCH', 'recipeName': '김치찌개', 'servings': 1, 'status': 'CONFIRMED'});

      expect(planned.cancelable, isTrue);
      expect(planned.status.label, '예정');
      expect(confirmed.cancelable, isFalse);
      expect(confirmed.status.label, '완료');
    });

    test('계획이 없는 날도 빈 배열로 온다', () {
      final day = MealPlanDay.fromJson({'date': '2026-08-25', 'meals': []});
      expect(day.meals, isEmpty);
      expect(day.date, DateTime(2026, 8, 25));
    });
  });

  group('미리보기 (API-41)', () {
    PreviewIngredient ingredient({
      num shortage = 0,
      bool trackable = true,
    }) {
      return PreviewIngredient.fromJson({
        'ingredientId': 171,
        'name': '두부(부침용)',
        'unitType': 'WEIGHT',
        'requiredQuantity': 400,
        'availableQuantity': 400 - shortage,
        'shortageQuantity': shortage,
        'trackable': trackable,
      });
    }

    test('부족량이 있으면 부족 재료로 본다', () {
      expect(ingredient(shortage: 100).isShort, isTrue);
      expect(ingredient().isShort, isFalse);
    });

    test('계량 제외 재료는 부족 판정에서 빠진다 (R-4)', () {
      // 서버가 shortage를 0으로 주지만, 값이 남아 있어도 화면은 부족으로 세지 않는다
      expect(ingredient(shortage: 100, trackable: false).isShort, isFalse);
    });
  });

  group('등록 결과 (API-42)', () {
    final detail = MealPlanDetail.fromJson({
      'id': 7,
      'planDate': '2026-08-22',
      'mealType': 'DINNER',
      'recipeId': 5,
      'recipeName': '된장찌개',
      'servings': 2,
      'status': 'PLANNED',
      'ingredients': [
        // 있는 만큼 예약되고 부족분은 장보기로 (D-010)
        {'ingredientId': 1, 'name': '두부', 'unitType': 'WEIGHT', 'requiredQuantity': 400,
          'reservedQuantity': 300, 'shortageQuantity': 100, 'trackable': true, 'addedToShoppingList': true},
        {'ingredientId': 2, 'name': '양파', 'unitType': 'WEIGHT', 'requiredQuantity': 100,
          'reservedQuantity': 100, 'shortageQuantity': 0, 'trackable': true, 'addedToShoppingList': false},
        {'ingredientId': 3, 'name': '소금', 'unitType': 'WEIGHT', 'requiredQuantity': 5,
          'reservedQuantity': 0, 'shortageQuantity': 0, 'trackable': false, 'addedToShoppingList': false},
      ],
    });

    test('예약이 잡힌 재료만 센다 (계량 제외는 예약 0)', () {
      expect(detail.reservedCount, 2);
    });

    test('장보기에 담긴 건수를 안내 문구에 쓴다', () {
      expect(detail.addedToShoppingCount, 1);
    });

    test('날짜와 끼니를 그대로 읽는다', () {
      expect(detail.planDate, DateTime(2026, 8, 22));
      expect(detail.mealType.label, '저녁');
      expect(toIsoDate(detail.planDate), '2026-08-22');
    });
  });

  group('날짜 표기', () {
    test('요일까지 붙여 보여준다', () {
      expect(formatDayLabel(DateTime(2026, 8, 21)), '8월 21일 (금)');
    });

    test('오늘·내일은 이름으로 부른다', () {
      expect(relativeDayLabel(today()), '오늘');
      expect(relativeDayLabel(today().add(const Duration(days: 1))), '내일');
      expect(relativeDayLabel(today().add(const Duration(days: 3))), isNull);
    });
  });
}
