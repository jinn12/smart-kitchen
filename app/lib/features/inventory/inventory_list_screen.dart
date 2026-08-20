import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api_exception.dart';
import 'expiry_badge.dart';
import 'inventory_api.dart';
import 'inventory_detail_screen.dart';
import 'inventory_add_screen.dart';
import 'inventory_models.dart';

/// S-11 재고 목록. 냉장고 탭의 시작 화면.
class InventoryListScreen extends StatefulWidget {
  const InventoryListScreen({super.key});

  @override
  State<InventoryListScreen> createState() => _InventoryListScreenState();
}

class _InventoryListScreenState extends State<InventoryListScreen> {
  StorageLocation? _filter;
  bool _loading = true;
  String? _error;
  List<InventoryItemSummary> _items = const [];
  List<InventoryItemSummary> _expiring = const [];

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
    final api = context.read<InventoryApi>();
    try {
      // 임박 섹션(API-24)은 필터와 무관하게 가구 전체 기준으로 보여준다
      final results = await Future.wait([
        api.list(storage: _filter),
        api.expiring(),
      ]);
      if (!mounted) return;
      setState(() {
        _items = results[0];
        _expiring = results[1];
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

  Future<void> _openDetail(InventoryItemSummary item) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => InventoryDetailScreen(
          ingredientId: item.ingredientId,
          name: item.name,
        ),
      ),
    );
    if (changed == true) _load();
  }

  Future<void> _openAdd() async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const InventoryAddScreen()),
    );
    if (added == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('냉장고'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
            tooltip: '새로고침',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAdd,
        icon: const Icon(Icons.add),
        label: const Text('재고 등록'),
      ),
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

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        children: [
          if (_expiring.isNotEmpty) _buildExpiringSection(),
          _buildFilterBar(),
          if (_items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: Text('재고가 없습니다. 오른쪽 아래에서 등록해 보세요.')),
            )
          else
            ..._items.map(_buildTile),
          const SizedBox(height: 80), // FAB에 가리지 않도록
        ],
      ),
    );
  }

  Widget _buildExpiringSection() {
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      color: Colors.orange.withValues(alpha: 0.06),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Text('임박·만료 ${_expiring.length}건',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          ..._expiring.map((e) => ListTile(
                dense: true,
                title: Text(e.name),
                subtitle: Text('${e.storageLocation.label} · 가용 ${formatQuantity(e.availableQuantity)}${unitLabelOf(e.unitType)}'),
                trailing: ExpiryBadge(status: e.expiryStatus, dday: e.dday),
                onTap: () => _openDetail(e),
              )),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Wrap(
        spacing: 8,
        children: [
          ChoiceChip(
            label: const Text('전체'),
            selected: _filter == null,
            onSelected: (_) {
              setState(() => _filter = null);
              _load();
            },
          ),
          ...StorageLocation.values.map((s) => ChoiceChip(
                label: Text(s.label),
                selected: _filter == s,
                onSelected: (_) {
                  setState(() => _filter = s);
                  _load();
                },
              )),
        ],
      ),
    );
  }

  Widget _buildTile(InventoryItemSummary item) {
    final unit = unitLabelOf(item.unitType);
    final reserved = item.reservedQuantity.toDouble() > 0
        ? ' (예약 ${formatQuantity(item.reservedQuantity)}$unit)'
        : '';
    return ListTile(
      title: Text(item.name),
      subtitle: Text(
        '${item.storageLocation.label} · '
        '가용 ${formatQuantity(item.availableQuantity)}$unit / '
        '총 ${formatQuantity(item.totalQuantity)}$unit$reserved',
      ),
      trailing: ExpiryBadge(status: item.expiryStatus, dday: item.dday),
      onTap: () => _openDetail(item),
    );
  }
}
