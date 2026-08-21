import 'package:flutter/material.dart';
import '../inventory/inventory_list_screen.dart';
import '../mealplan/meal_plan_week_screen.dart';
import '../recipe/recipe_list_screen.dart';
import '../shopping/shopping_list_screen.dart';

/// 4탭 셸 (D-012). 시작 탭은 냉장고.
///
/// 탭 상태(스크롤·주간 위치)를 살리려고 IndexedStack을 쓰기 때문에,
/// 탭을 다시 열어도 initState가 돌지 않는다. 순환 구조상 한 탭의 조작이
/// 다른 탭의 숫자를 바꾸므로(계획 등록 → 가용 재고 감소, 부족분 → 장보기)
/// 탭이 활성화될 때 그 화면에 새로고침을 직접 요청한다.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  final _inventoryKey = GlobalKey<InventoryListScreenState>();
  final _recipeKey = GlobalKey<RecipeListScreenState>();
  final _mealPlanKey = GlobalKey<MealPlanWeekScreenState>();
  final _shoppingKey = GlobalKey<ShoppingListScreenState>();

  late final List<Widget> _tabs = [
    InventoryListScreen(key: _inventoryKey),
    RecipeListScreen(key: _recipeKey),
    MealPlanWeekScreen(key: _mealPlanKey),
    ShoppingListScreen(key: _shoppingKey),
  ];

  void _onSelect(int i) {
    setState(() => _index = i);
    switch (i) {
      case 0:
        _inventoryKey.currentState?.reload();
      case 1:
        _recipeKey.currentState?.reload();
      case 2:
        _mealPlanKey.currentState?.reload();
      case 3:
        _shoppingKey.currentState?.reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _onSelect,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.kitchen_outlined), selectedIcon: Icon(Icons.kitchen), label: '냉장고'),
          NavigationDestination(icon: Icon(Icons.restaurant_outlined), selectedIcon: Icon(Icons.restaurant), label: '요리'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: '식탁'),
          NavigationDestination(icon: Icon(Icons.shopping_cart_outlined), selectedIcon: Icon(Icons.shopping_cart), label: '장보기'),
        ],
      ),
    );
  }
}
