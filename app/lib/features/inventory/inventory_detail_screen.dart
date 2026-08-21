import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api_exception.dart';
import '../../core/app_theme.dart';
import '../ingredient/ingredient_models.dart';
import 'expiry_badge.dart';
import 'inventory_api.dart';
import 'inventory_models.dart';

/// S-12 식재료 상세. 요약 + 배치 목록(FEFO 순) + 변동 기록.
class InventoryDetailScreen extends StatefulWidget {
  const InventoryDetailScreen({
    super.key,
    required this.ingredientId,
    required this.name,
  });

  final int ingredientId;
  final String name;

  @override
  State<InventoryDetailScreen> createState() => _InventoryDetailScreenState();
}

class _InventoryDetailScreenState extends State<InventoryDetailScreen> {
  bool _loading = true;
  String? _error;
  InventoryDetail? _detail;

  /// 목록으로 돌아갈 때 새로고침이 필요한지
  bool _changed = false;

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
      final detail = await context.read<InventoryApi>().detail(widget.ingredientId);
      if (!mounted) return;
      setState(() {
        _detail = detail;
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

  Future<void> _runBatchAction(InventoryBatch batch, String action) async {
    final api = context.read<InventoryApi>();
    num? quantity;
    if (action == 'ADJUST') {
      quantity = await _askQuantity(batch);
      if (quantity == null) return;
    } else {
      final label = action == 'CONSUME' ? '소진' : '폐기';
      final ok = await _confirm('$label 처리', '이 배치를 $label 처리할까요? 잔량이 0이 돼요.');
      if (ok != true) return;
    }
    try {
      await api.updateBatch(batch.id, action, quantity: quantity);
      _changed = true;
      if (!mounted) return;
      _toast('처리했어요');
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      _toast(e.message);
    }
  }

  Future<num?> _askQuantity(InventoryBatch batch) async {
    final controller = TextEditingController(text: formatQuantity(batch.quantity));
    return showDialog<num>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('수량 수정'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: '잔량', helperText: '0도 입력할 수 있어요'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          FilledButton(
            onPressed: () {
              final v = num.tryParse(controller.text.trim());
              if (v == null || v < 0) return;
              Navigator.pop(ctx, v);
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirm(String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('확인')),
        ],
      ),
    );
  }

  Future<void> _changeStorage() async {
    final api = context.read<InventoryApi>();
    final current = _detail!.summary.storageLocation;
    final picked = await showDialog<StorageLocation>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('보관 장소 변경'),
        children: StorageLocation.values
            .map((s) => ListTile(
                  title: Text(s.label),
                  trailing: s == current
                      ? Icon(Icons.check, color: Theme.of(ctx).colorScheme.primary)
                      : null,
                  onTap: () => Navigator.pop(ctx, s),
                ))
            .toList(),
      ),
    );
    if (picked == null || picked == current) return;
    try {
      await api.changeStorage(widget.ingredientId, picked);
      _changed = true;
      if (!mounted) return;
      _toast('${picked.label}으로 옮겼어요');
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      _toast(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _changed);
      },
      child: Scaffold(
        appBar: AppBar(title: Text(widget.name)),
        body: _buildBody(),
      ),
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

    final d = _detail!;
    final unit = unitLabelOf(d.summary.unitType);
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Card(
          margin: const EdgeInsets.all(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(d.summary.name,
                          style: Theme.of(context).textTheme.titleLarge),
                    ),
                    ExpiryBadge(status: d.summary.expiryStatus, dday: d.summary.dday),
                  ],
                ),
                const SizedBox(height: 8),
                Text('총 ${formatQuantity(d.summary.totalQuantity)}$unit · '
                    '예약 ${formatQuantity(d.summary.reservedQuantity)}$unit · '
                    '가용 ${formatQuantity(d.summary.availableQuantity)}$unit'),
                if (d.summary.nearestExpiryDate != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('가장 임박한 유통기한 ${d.summary.nearestExpiryDate}'),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Chip(label: Text(d.summary.storageLocation.label)),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: _changeStorage,
                      icon: const Icon(Icons.swap_horiz, size: 18),
                      label: const Text('보관 장소 변경'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        _sectionTitle('배치 (유통기한 빠른 순)'),
        if (d.batches.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('남은 배치가 없어요.'),
          )
        else
          ...d.batches.map((b) => _buildBatchTile(b, unit)),
        const Divider(height: 32),
        _sectionTitle('변동 기록'),
        if (d.history.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('아직 기록이 없어요.'),
          )
        else
          ...d.history.map((h) => ListTile(
                dense: true,
                leading: Icon(
                  h.quantity.toDouble() >= 0 ? Icons.add_circle_outline : Icons.remove_circle_outline,
                  color: h.quantity.toDouble() >= 0 ? StatusColors.secured : StatusColors.expired,
                  size: 20,
                ),
                title: Text('${h.typeLabel} ${formatQuantity(h.quantity)}$unit'),
                subtitle: Text('${h.sourceLabel} · ${_formatDateTime(h.createdAt)}'),
              )),
      ],
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
      );

  Widget _buildBatchTile(InventoryBatch b, String unit) {
    return ListTile(
      title: Text('${formatQuantity(b.quantity)}$unit'),
      subtitle: Text('구매 ${b.purchasedAt}'
          '${b.expiryDate != null ? ' · 유통기한 ${b.expiryDate}' : ' · 유통기한 없음'}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (b.dday != null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text('D-${b.dday}', style: const TextStyle(fontSize: 12)),
            ),
          PopupMenuButton<String>(
            onSelected: (action) => _runBatchAction(b, action),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'ADJUST', child: Text('수량 수정')),
              PopupMenuItem(value: 'CONSUME', child: Text('소진 처리')),
              PopupMenuItem(value: 'DISCARD', child: Text('폐기 처리')),
            ],
          ),
        ],
      ),
    );
  }

  /// 2026-08-20T05:23:19.123Z -> 2026-08-20 05:23
  String _formatDateTime(String raw) {
    if (raw.length < 16) return raw;
    return '${raw.substring(0, 10)} ${raw.substring(11, 16)}';
  }
}
