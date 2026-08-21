import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api_exception.dart';
import '../../core/date_utils.dart';
import '../ingredient/ingredient_models.dart' show formatQuantity;
import 'meal_plan_api.dart';
import 'meal_plan_models.dart';

/// ③ 부족 재료 일괄 안내 (D-010). 항목별로 "장보기 담기"를 고르고 등록한다.
///
/// 부족해도 등록은 막지 않는다 — "있는 만큼 사용"이 기본이고(R-1),
/// 부족분을 장보기에 담을지가 사용자의 선택이다.
class MealPlanPreviewScreen extends StatefulWidget {
  const MealPlanPreviewScreen({
    super.key,
    required this.preview,
    required this.planDate,
    required this.mealType,
  });

  final MealPlanPreview preview;
  final DateTime planDate;
  final MealType mealType;

  @override
  State<MealPlanPreviewScreen> createState() => _MealPlanPreviewScreenState();
}

class _MealPlanPreviewScreenState extends State<MealPlanPreviewScreen> {
  /// 장보기에 담을 부족 재료. 기본은 전부 담기 — 사고 나서 후회하는 쪽이 낫다
  late final Set<int> _toShopping = {
    for (final i in widget.preview.ingredients)
      if (i.isShort) i.ingredientId,
  };

  bool _saving = false;

  List<PreviewIngredient> get _shortages =>
      widget.preview.ingredients.where((i) => i.isShort).toList();

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final created = await context.read<MealPlanApi>().create(
            recipeId: widget.preview.recipeId,
            planDate: widget.planDate,
            mealType: widget.mealType,
            servings: widget.preview.servings,
            addToShoppingIngredientIds: _toShopping.toList(),
          );
      if (!mounted) return;
      Navigator.pop(context, created);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('부족 재료 확인')),
      body: ListView(
        children: [
          _buildHeader(),
          const Divider(height: 1),
          ...widget.preview.ingredients.map(_buildIngredientTile),
          const SizedBox(height: 16),
        ],
      ),
      bottomNavigationBar: _buildSaveBar(),
    );
  }

  Widget _buildHeader() {
    final p = widget.preview;
    final short = p.shortageCount;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(p.recipeName, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text('${formatDayLabel(widget.planDate)} ${widget.mealType.label} · ${p.servings}인분'),
          if (p.servings != p.recipeServings)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '요리 기준 ${p.recipeServings}인분을 ${p.servings}인분으로 환산한 필요량이에요.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: short > 0
                  ? Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.5)
                  : Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(short > 0 ? Icons.shopping_cart_outlined : Icons.check_circle_outline,
                    size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    short > 0
                        ? '부족한 재료가 $short개 있어요. 있는 만큼 예약하고, 부족분은 장보기에 담을 수 있어요.'
                        : '재료가 모두 충분해요. 등록하면 필요한 만큼 예약됩니다.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientTile(PreviewIngredient item) {
    final unit = item.unitLabel;
    final need = '필요 ${formatQuantity(item.requiredQuantity)}$unit';

    // trackable=false는 계량 자체를 하지 않는다 (R-4) — 예약·부족 판단에서 빠진다
    if (!item.trackable) {
      return ListTile(
        title: Text(item.name, style: const TextStyle(color: Colors.grey)),
        subtitle: Text(need, style: const TextStyle(color: Colors.grey)),
        trailing: const Text('계량 제외', style: TextStyle(color: Colors.grey)),
      );
    }

    if (!item.isShort) {
      return ListTile(
        title: Text(item.name),
        subtitle: Text('$need · 가용 ${formatQuantity(item.availableQuantity)}$unit'),
        trailing: const Icon(Icons.check, color: Colors.green, size: 20),
      );
    }

    final error = Theme.of(context).colorScheme.error;
    final checked = _toShopping.contains(item.ingredientId);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.name, style: TextStyle(color: error, fontWeight: FontWeight.bold)),
          Text('$need · 가용 ${formatQuantity(item.availableQuantity)}$unit · '
              '${formatQuantity(item.shortageQuantity)}$unit 부족'),
          CheckboxListTile(
            value: checked,
            onChanged: (v) => setState(() {
              if (v == true) {
                _toShopping.add(item.ingredientId);
              } else {
                _toShopping.remove(item.ingredientId);
              }
            }),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text('장보기에 ${formatQuantity(item.shortageQuantity)}$unit 담기'),
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }

  Widget _buildSaveBar() {
    final shortages = _shortages.length;
    final picked = _toShopping.length;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (shortages > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '부족 $shortages개 중 $picked개를 장보기에 담습니다',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('계획 등록'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
