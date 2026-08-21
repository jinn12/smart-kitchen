import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api_exception.dart';
import '../../core/empty_state.dart';
import '../ingredient/ingredient_models.dart';
import '../ingredient/ingredient_picker.dart';
import 'shopping_api.dart';
import 'shopping_models.dart';

/// S-41 장보기 목록 + S-42 구매 완료. 가구당 장바구니는 하나뿐이다 (D-009).
class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => ShoppingListScreenState();
}

class ShoppingListScreenState extends State<ShoppingListScreen> {
  bool _loading = true;
  bool _completing = false;
  String? _error;
  List<ShoppingItem> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// 탭으로 돌아올 때마다 셸이 부른다 — 식탁에서 담긴 부족분이 바로 보이도록
  void reload() {
    if (!_loading) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await context.read<ShoppingApi>().list();
      if (!mounted) return;
      setState(() {
        _items = list.items;
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

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  List<ShoppingItem> get _unchecked => _items.where((i) => !i.isChecked).toList();
  List<ShoppingItem> get _checked => _items.where((i) => i.isChecked).toList();

  void _replace(ShoppingItem updated) {
    setState(() {
      _items = [
        for (final i in _items) i.id == updated.id ? updated : i,
      ];
    });
  }

  Future<void> _toggle(ShoppingItem item) async {
    try {
      final updated = await context
          .read<ShoppingApi>()
          .updateItem(item.id, isChecked: !item.isChecked);
      if (!mounted) return;
      _replace(updated);
    } on ApiException catch (e) {
      if (!mounted) return;
      _toast(e.message);
    }
  }

  Future<void> _editQuantity(ShoppingItem item) async {
    final value = await askQuantity(
      context,
      name: item.name,
      unitLabel: item.unitLabel,
      initial: item.quantity,
      confirmLabel: '저장',
    );
    if (value == null || !mounted) return;
    try {
      final updated =
          await context.read<ShoppingApi>().updateItem(item.id, quantity: value);
      if (!mounted) return;
      _replace(updated);
    } on ApiException catch (e) {
      if (!mounted) return;
      _toast(e.message);
    }
  }

  /// 스와이프 확정 단계에서 실제로 지운다. 목록에서 빼는 건 onDismissed가 맡는다
  Future<bool> _delete(ShoppingItem item) async {
    try {
      await context.read<ShoppingApi>().deleteItem(item.id);
      if (!mounted) return false;
      _toast('${item.name}을(를) 삭제했습니다');
      return true;
    } on ApiException catch (e) {
      if (!mounted) return false;
      _toast(e.message);
      return false;
    }
  }

  Future<void> _addManually() async {
    // 잔량 관리를 하지 않는 재료도 장보기에는 수동으로 담을 수 있다 (D-017)
    final ingredient = await pickIngredient(context, title: '장보기 추가');
    if (ingredient == null || !mounted) return;
    final quantity = await askQuantity(
      context,
      name: ingredient.name,
      unitLabel: ingredient.unitLabel,
      hint: ingredient.isTrackable
          ? null
          : '잔량 관리를 하지 않는 재료라 구매 완료 시 재고에는 등록되지 않고 목록에서만 빠집니다 (R-4)',
      confirmLabel: '담기',
    );
    if (quantity == null || !mounted) return;
    try {
      final list = await context
          .read<ShoppingApi>()
          .addItem(ingredientId: ingredient.id, quantity: quantity);
      if (!mounted) return;
      setState(() => _items = list.items);
      _toast('${ingredient.name}을(를) 담았습니다');
    } on ApiException catch (e) {
      if (!mounted) return;
      _toast(e.message);
    }
  }

  Future<void> _complete() async {
    final count = _checked.length;
    if (count == 0) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('구매 완료'),
        content: Text('체크한 $count건이 재고에 등록됩니다.\n'
            '구매일은 오늘로, 유통기한은 재료별 기본값으로 계산됩니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('닫기')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('구매 완료')),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _completing = true);
    try {
      final result = await context.read<ShoppingApi>().complete();
      if (!mounted) return;
      setState(() => _completing = false);
      await _showResult(result);
      if (!mounted) return;
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _completing = false);
      _toast(e.message);
    }
  }

  Future<void> _showResult(ShoppingCompleteResult result) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('재고에 반영했습니다'),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (result.inventories.isEmpty)
                const Text('재고로 관리하는 항목이 없어 목록에서만 정리했습니다.')
              else
                ConstrainedBox(
                  // 다이얼로그 안이라 높이가 무한대다 — 목록에 상한을 직접 준다
                  constraints: const BoxConstraints(maxHeight: 280),
                  child: ListView(
                    shrinkWrap: true,
                    children: result.inventories.map((inv) {
                      final unit = unitLabelOf(inv.unitType);
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(inv.name),
                        subtitle: Text(
                          '${inv.storageLocation.label} · '
                          '총 ${formatQuantity(inv.totalQuantity)}$unit · '
                          '가용 ${formatQuantity(inv.availableQuantity)}$unit',
                        ),
                      );
                    }).toList(),
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                result.carriedOverCount > 0
                    ? '체크하지 않은 ${result.carriedOverCount}건은 목록에 남겨뒀어요.'
                    : '남은 항목이 없어 장보기 목록이 비었어요.',
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('확인')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('장보기'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
            tooltip: '새로고침',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addManually,
        icon: const Icon(Icons.add),
        label: const Text('직접 추가'),
      ),
      body: _buildBody(),
      bottomNavigationBar: _loading || _error != null ? null : _buildCompleteBar(),
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
    if (_items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: [
            EmptyState(
              icon: Icons.shopping_cart_outlined,
              title: '장바구니가 비어 있어요',
              description: '식탁에서 계획을 세우면 부족한 재료가 여기로 담겨요.\n지금 살 것이 있다면 직접 추가해도 돼요.',
              actionLabel: '직접 추가하기',
              onAction: _addManually,
            ),
          ],
        ),
      );
    }

    final unchecked = _unchecked;
    final checked = _checked;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 96), // FAB·하단 버튼에 가리지 않도록
        children: [
          _sectionTitle('살 것 ${unchecked.length}건'),
          if (unchecked.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('모두 담았어요.', style: TextStyle(color: Colors.grey)),
            )
          else
            ...unchecked.map(_buildItemTile),
          if (checked.isNotEmpty) ...[
            const Divider(height: 24),
            _sectionTitle('담음 ${checked.length}건'),
            ...checked.map(_buildItemTile),
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
      );

  Widget _buildItemTile(ShoppingItem item) {
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        color: Theme.of(context).colorScheme.errorContainer,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline),
      ),
      confirmDismiss: (_) => _delete(item),
      onDismissed: (_) =>
          setState(() => _items = _items.where((i) => i.id != item.id).toList()),
      child: ListTile(
        leading: Checkbox(
          value: item.isChecked,
          onChanged: (_) => _toggle(item),
        ),
        title: Text(
          item.name,
          style: TextStyle(
            decoration: item.isChecked ? TextDecoration.lineThrough : null,
            color: item.isChecked ? Colors.grey : null,
          ),
        ),
        subtitle: Row(
          children: [
            Text(item.quantityLabel),
            const SizedBox(width: 6),
            _SourceChip(source: item.source),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit_outlined, size: 20),
          tooltip: '수량 수정',
          onPressed: () => _editQuantity(item),
        ),
        onTap: () => _toggle(item),
      ),
    );
  }

  Widget _buildCompleteBar() {
    final count = _checked.length;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: FilledButton(
          onPressed: count == 0 || _completing ? null : _complete,
          child: _completing
              ? const SizedBox(
                  height: 20, width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text('구매 완료 ($count건)'),
        ),
      ),
    );
  }
}

class _SourceChip extends StatelessWidget {
  const _SourceChip({required this.source});

  final ShoppingItemSource source;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(source.label, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}
