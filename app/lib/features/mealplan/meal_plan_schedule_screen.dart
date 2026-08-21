import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api_exception.dart';
import '../../core/date_utils.dart';
import '../recipe/recipe_models.dart';
import '../recipe/servings_stepper.dart';
import 'meal_plan_api.dart';
import 'meal_plan_models.dart';
import 'meal_plan_preview_screen.dart';

/// ② 언제·몇 인분 먹을지 정한다. 여기서는 아직 아무것도 예약하지 않는다.
class MealPlanScheduleScreen extends StatefulWidget {
  const MealPlanScheduleScreen({super.key, required this.recipe});

  final RecipeSummary recipe;

  @override
  State<MealPlanScheduleScreen> createState() => _MealPlanScheduleScreenState();
}

class _MealPlanScheduleScreenState extends State<MealPlanScheduleScreen> {
  late DateTime _date = today();
  MealType _mealType = MealType.dinner;
  late int _servings = widget.recipe.servings;
  bool _loading = false;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      // 지난 날짜에는 계획을 세울 수 없다 (API-42가 400으로 막는 조건을 화면에서 먼저 막는다)
      firstDate: today(),
      lastDate: today().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() => _date = DateTime(picked.year, picked.month, picked.day));
  }

  Future<void> _next() async {
    setState(() => _loading = true);
    try {
      final preview = await context.read<MealPlanApi>().preview(
            recipeId: widget.recipe.id,
            servings: _servings,
          );
      if (!mounted) return;
      setState(() => _loading = false);
      final created = await Navigator.of(context).push<MealPlanDetail>(
        MaterialPageRoute(
          builder: (_) => MealPlanPreviewScreen(
            preview: preview,
            planDate: _date,
            mealType: _mealType,
          ),
        ),
      );
      if (created == null || !mounted) return;
      Navigator.pop(context, created);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final relative = relativeDayLabel(_date);
    return Scaffold(
      appBar: AppBar(title: const Text('언제 먹을까요?')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(widget.recipe.name, style: Theme.of(context).textTheme.titleLarge),
          Text('요리 기준 ${widget.recipe.servings}인분 · 재료 ${widget.recipe.ingredientCount}개',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 24),
          _label('날짜'),
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today, size: 18),
            label: Text(
              '${formatDayLabel(_date)}${relative != null ? ' · $relative' : ''}',
            ),
          ),
          const SizedBox(height: 24),
          _label('끼니'),
          SegmentedButton<MealType>(
            segments: MealType.values
                .map((m) => ButtonSegment(value: m, label: Text(m.label)))
                .toList(),
            selected: {_mealType},
            onSelectionChanged: (s) => setState(() => _mealType = s.first),
          ),
          const SizedBox(height: 24),
          _label('인분'),
          Row(
            children: [
              ServingsStepper(
                servings: _servings,
                onChanged: (v) => setState(() => _servings = v),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _servings == widget.recipe.servings
                      ? '요리에 등록된 기준 인분 그대로예요.'
                      // D-015: 필요량 = 재료량 × (계획 인분 ÷ 기준 인분)
                      : '재료 필요량이 기준 ${widget.recipe.servings}인분의 '
                          '${(_servings / widget.recipe.servings).toStringAsFixed(2)}배로 계산돼요.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton(
            onPressed: _loading ? null : _next,
            child: _loading
                ? const SizedBox(
                    height: 20, width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('부족 재료 확인'),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
      );
}
