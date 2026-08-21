import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api_exception.dart';
import '../recipe/recipe_api.dart';
import '../recipe/recipe_list_screen.dart' show CookableBadge;
import '../recipe/recipe_models.dart';
import 'meal_plan_models.dart';
import 'meal_plan_schedule_screen.dart';

/// S-32 계획 등록의 시작점. ① 요리 → ② 날짜·끼니·인분 → ③ 미리보기 → ④ 등록.
/// 끝까지 마치면 등록된 계획을, 도중에 그만두면 null을 돌려준다.
Future<MealPlanDetail?> startMealPlanFlow(BuildContext context) {
  return Navigator.of(context).push<MealPlanDetail>(
    MaterialPageRoute(builder: (_) => const MealPlanRecipePickScreen()),
  );
}

/// ① 어떤 요리를 먹을지 고른다 (API-30 재사용)
class MealPlanRecipePickScreen extends StatefulWidget {
  const MealPlanRecipePickScreen({super.key});

  @override
  State<MealPlanRecipePickScreen> createState() => _MealPlanRecipePickScreenState();
}

class _MealPlanRecipePickScreenState extends State<MealPlanRecipePickScreen> {
  bool _loading = true;
  String? _error;
  List<RecipeSummary> _recipes = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final recipes = await context.read<RecipeApi>().list();
      if (!mounted) return;
      setState(() {
        _recipes = recipes;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _pick(RecipeSummary recipe) async {
    final created = await Navigator.of(context).push<MealPlanDetail>(
      MaterialPageRoute(builder: (_) => MealPlanScheduleScreen(recipe: recipe)),
    );
    if (created == null || !mounted) return;
    Navigator.pop(context, created);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('요리 선택')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!),
            const SizedBox(height: 12),
            FilledButton(onPressed: _load, child: const Text('다시 시도')),
          ],
        ),
      );
    }
    if (_recipes.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('등록된 요리가 없어요.\n요리 탭에서 먼저 요리를 등록해 주세요.',
              textAlign: TextAlign.center),
        ),
      );
    }
    return ListView.builder(
      itemCount: _recipes.length,
      itemBuilder: (_, i) {
        final r = _recipes[i];
        return ListTile(
          title: Text(r.name),
          subtitle: Text('${r.servings}인분 · 재료 ${r.ingredientCount}개'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 등록 분량 기준 배지다 (D-024). 인분을 올리면 부족해질 수 있다
              if (r.cookableNow) const CookableBadge(),
              const Icon(Icons.chevron_right),
            ],
          ),
          onTap: () => _pick(r),
        );
      },
    );
  }
}
