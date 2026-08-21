import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api_exception.dart';
import '../../core/app_theme.dart';
import '../../core/empty_state.dart';
import '../ingredient/ingredient_models.dart';
import '../settings/settings_screen.dart';
import 'expiry_badge.dart';
import 'inventory_add_screen.dart';
import 'inventory_api.dart';
import 'inventory_detail_screen.dart';
import 'inventory_models.dart';

/// S-11 재고 목록. 냉장고 탭의 시작 화면.
class InventoryListScreen extends StatefulWidget {
  const InventoryListScreen({super.key});

  @override
  State<InventoryListScreen> createState() => InventoryListScreenState();
}

class InventoryListScreenState extends State<InventoryListScreen> {
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

  /// 탭으로 돌아올 때마다 셸이 부른다 — 계획 예약·구매 완료가 가용 수량에 바로 보이도록
  void reload() {
    if (!_loading) _load();
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
          // 설정·계정은 탭이 아니라 상단 아이콘으로 들어간다 (D-012)
          IconButton(
            tooltip: '설정',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
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
            // 필터 때문에 비어 보이는 것과 정말 재고가 없는 것은 다른 상황이다
            _filter != null
                ? EmptyState(
                    icon: Icons.filter_alt_off_outlined,
                    title: '${_filter!.label}에 둔 재료가 없어요',
                    description: '다른 보관 장소를 보거나 전체로 바꿔보세요.',
                    actionLabel: '전체 보기',
                    onAction: () {
                      setState(() => _filter = null);
                      _load();
                    },
                  )
                : EmptyState(
                    icon: Icons.kitchen_outlined,
                    title: '장 봐온 재료를 등록해보세요',
                    description: '재료를 넣어두면 요리·식단·장보기가 자동으로 이어져요.',
                    actionLabel: '재료 등록하기',
                    onAction: _openAdd,
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
      color: StatusColors.expiring.withValues(alpha: 0.06),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: StatusColors.expiring, size: 20),
                const SizedBox(width: 8),
                Text('유통기한을 확인해 주세요 · ${_expiring.length}건',
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
