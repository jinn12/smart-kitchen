import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api_exception.dart';
import '../ingredient/ingredient_models.dart';
import '../ingredient/ingredient_picker.dart';
import 'inventory_api.dart';

/// 담은 항목 하나 (아직 서버에 보내기 전)
class _PickedItem {
  _PickedItem(this.ingredient, this.quantity);

  final IngredientSearchResult ingredient;
  num quantity;
}

/// S-13 식재료 일괄 등록. 검색 → 여러 개 담기 → 수량 확인 → 한 번에 저장.
/// AI 사진 인식(D-007)이 나중에 이 화면의 "담긴 목록"을 프리필로 재사용한다.
class InventoryAddScreen extends StatefulWidget {
  const InventoryAddScreen({super.key});

  @override
  State<InventoryAddScreen> createState() => _InventoryAddScreenState();
}

class _InventoryAddScreenState extends State<InventoryAddScreen> {
  final List<_PickedItem> _picked = [];
  bool _saving = false;

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pick(IngredientSearchResult ingredient) async {
    // 잔량 관리를 하지 않는 재료는 재고로 담을 수 없다 (R-4) — 서버도 400으로 막는다
    if (!ingredient.isTrackable) {
      _toast('${ingredient.name}은(는) 잔량 관리를 하지 않는 재료라 재고에 담을 수 없습니다');
      return;
    }
    if (_picked.any((p) => p.ingredient.id == ingredient.id)) {
      _toast('이미 담은 재료입니다');
      return;
    }
    final quantity = await _askQuantity(ingredient);
    if (quantity == null) return;
    setState(() => _picked.add(_PickedItem(ingredient, quantity)));
  }

  Future<num?> _askQuantity(IngredientSearchResult ingredient, {num? initial}) {
    final shelf = ingredient.defaultShelfLifeDays;
    return askQuantity(
      context,
      name: ingredient.name,
      unitLabel: ingredient.unitLabel,
      initial: initial,
      // 등록 시 서버가 채우는 기본값을 미리 보여준다 (IA의 "기본값 확인")
      hint: shelf != null
          ? '${ingredient.defaultStorage.label}에 보관됩니다 · 유통기한은 구매일+$shelf일'
          : '${ingredient.defaultStorage.label}에 보관됩니다 · 권장 소비 기간이 없어 유통기한 없이 등록됩니다',
      confirmLabel: '담기',
    );
  }

  Future<void> _editPicked(_PickedItem item) async {
    final v = await _askQuantity(item.ingredient, initial: item.quantity);
    if (v == null) return;
    setState(() => item.quantity = v);
  }

  Future<void> _save() async {
    if (_picked.isEmpty) return;
    setState(() => _saving = true);
    try {
      await context.read<InventoryApi>().addItems(
            _picked
                .map((p) => (ingredientId: p.ingredient.id, quantity: p.quantity))
                .toList(),
          );
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _toast(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('재고 등록')),
      body: IngredientSearchPanel(
        onSelect: _pick,
        isPicked: (r) => _picked.any((p) => p.ingredient.id == r.id),
        belowSearchBar: _picked.isEmpty ? null : _buildPickedSection(),
        // 재고는 잔량을 세는 것이라 관리 대상만 담을 수 있다 (R-4)
        allowNonTrackable: false,
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton(
            onPressed: _picked.isEmpty || _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 20, width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text('${_picked.length}건 등록'),
          ),
        ),
      ),
    );
  }

  Widget _buildPickedSection() {
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('담은 재료 ${_picked.length}건',
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
