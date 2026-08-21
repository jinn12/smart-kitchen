import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api_exception.dart';
import '../ingredient/ingredient_models.dart';
import '../ingredient/ingredient_picker.dart';
import 'recipe_api.dart';
import 'recipe_models.dart';
import 'servings_stepper.dart';

/// 담은 재료 하나 (아직 서버에 보내기 전)
class _PickedItem {
  _PickedItem(this.ingredient, this.quantity);

  final IngredientSearchResult ingredient;
  num quantity;
}

/// S-23 직접 입력. 이름·인분을 정하고 재료를 담는다 (S-13과 같은 검색 UX).
class RecipeManualAddScreen extends StatefulWidget {
  const RecipeManualAddScreen({super.key});

  @override
  State<RecipeManualAddScreen> createState() => _RecipeManualAddScreenState();
}

class _RecipeManualAddScreenState extends State<RecipeManualAddScreen> {
  final _name = TextEditingController();
  int _servings = 1;
  final List<_PickedItem> _picked = [];
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pick(IngredientSearchResult ingredient) async {
    // 같은 재료를 두 번 넣으면 서버가 400으로 막는다 (API-31)
    if (_picked.any((p) => p.ingredient.id == ingredient.id)) {
      _toast('이미 담은 재료입니다');
      return;
    }
    final quantity = await askQuantity(
      context,
      name: ingredient.name,
      unitLabel: ingredient.unitLabel,
      hint: ingredient.isTrackable
          ? null
          : '잔량 관리를 하지 않는 재료라 부족 판정에서는 빠집니다 (R-4)',
      confirmLabel: '담기',
    );
    if (quantity == null) return;
    setState(() => _picked.add(_PickedItem(ingredient, quantity)));
  }

  Future<void> _editPicked(_PickedItem item) async {
    final v = await askQuantity(
      context,
      name: item.ingredient.name,
      unitLabel: item.ingredient.unitLabel,
      initial: item.quantity,
    );
    if (v == null) return;
    setState(() => item.quantity = v);
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      _toast('요리 이름을 입력해주세요');
      return;
    }
    if (_picked.isEmpty) {
      _toast('재료를 한 개 이상 담아주세요');
      return;
    }
    setState(() => _saving = true);
    try {
      final created = await context.read<RecipeApi>().create(
            source: RecipeSource.manual,
            name: name,
            servings: _servings,
            ingredients: _picked
                .map((p) => (ingredientId: p.ingredient.id, quantity: p.quantity))
                .toList(),
          );
      if (!mounted) return;
      Navigator.pop(context, created);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _toast(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('직접 입력')),
      body: Column(
        children: [
          _buildBasicInfo(),
          Expanded(
            child: IngredientSearchPanel(
              onSelect: _pick,
              isPicked: (r) => _picked.any((p) => p.ingredient.id == r.id),
              belowSearchBar: _picked.isEmpty ? null : _buildPickedSection(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 20, width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text('요리 등록 (재료 ${_picked.length}개)'),
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: '요리 이름',
                hintText: '예: 우리집 된장찌개',
              ),
              textInputAction: TextInputAction.done,
            ),
          ),
          const SizedBox(width: 12),
          ServingsStepper(
            servings: _servings,
            onChanged: (v) => setState(() => _servings = v),
          ),
        ],
      ),
    );
  }

  Widget _buildPickedSection() {
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      margin: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('담은 재료 ${_picked.length}개',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _picked
                .map((p) => InputChip(
                      label: Text(
                          '${p.ingredient.name} ${formatQuantity(p.quantity)}${p.ingredient.unitLabel}'),
                      onPressed: () => _editPicked(p),
                      onDeleted: () => setState(() => _picked.remove(p)),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}
