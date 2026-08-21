import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api_exception.dart';
import '../../core/app_theme.dart';
import '../ingredient/ingredient_models.dart' show formatQuantity;
import '../ingredient/ingredient_picker.dart';
import 'recipe_api.dart';
import 'recipe_mapping_row.dart';
import 'recipe_models.dart';
import 'servings_stepper.dart';

/// S-23 "레시피에서 찾기"의 매핑 확인 화면 (API-34 → API-31).
///
/// 배치가 붙여둔 매핑을 그대로 믿지 않고 사용자가 줄마다 확인한다 (D-007).
class RecipeMappingScreen extends StatefulWidget {
  const RecipeMappingScreen({super.key, required this.masterId, required this.name});

  final int masterId;
  final String name;

  @override
  State<RecipeMappingScreen> createState() => _RecipeMappingScreenState();
}

class _RecipeMappingScreenState extends State<RecipeMappingScreen> {
  bool _loading = true;
  bool _saving = false;
  String? _error;
  RecipeMasterDetail? _master;
  List<MappingRow> _rows = const [];

  /// 마스터는 1인분 기준이라 기본 1에서 시작한다 (D-015)
  int _servings = 1;

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
      final master = await context.read<RecipeApi>().masterDetail(widget.masterId);
      if (!mounted) return;
      setState(() {
        _master = master;
        _rows = master.ingredients.map(MappingRow.new).toList();
        _servings = master.servings;
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

  int get _includedCount => _rows.where((r) => r.included).length;
  int get _attentionCount => _rows.where((r) => r.needsAttention).length;

  Future<void> _assign(MappingRow row) async {
    final picked = await pickIngredient(context, title: '재료 지정 — ${row.source.parsedName}');
    if (picked == null || !mounted) return;
    row.assign(id: picked.id, name: picked.name, unitType: picked.unitType);
    setState(() {});
    await _editQuantity(row);
  }

  Future<void> _editQuantity(MappingRow row) async {
    if (row.ingredientId == null) return;
    final value = await askQuantity(
      context,
      name: row.ingredientName!,
      unitLabel: row.unitLabel,
      initial: row.quantity ?? row.suggestedQuantity(row.unitType ?? ''),
      hint: '원문: ${row.source.rawText}',
      confirmLabel: '포함',
    );
    if (value == null || !mounted) return;
    setState(() => row.setQuantity(value));
  }

  Future<void> _save() async {
    final items = toRequestItems(_rows);
    if (items.isEmpty) {
      _toast('재료를 한 개 이상 포함해 주세요');
      return;
    }
    final duplicated = duplicatedIngredientIds(_rows);
    if (duplicated.isNotEmpty) {
      final names = _rows
          .where((r) => duplicated.contains(r.ingredientId))
          .map((r) => r.ingredientName!)
          .toSet()
          .join(', ');
      _toast('같은 재료가 두 번 포함됐어요 ($names). 한 줄만 남기고 수량을 합쳐 주세요');
      return;
    }
    if (_attentionCount > 0 && !await _confirmSkip()) return;

    if (!mounted) return;
    setState(() => _saving = true);
    try {
      final created = await context.read<RecipeApi>().create(
            source: RecipeSource.master,
            recipeMasterId: widget.masterId,
            servings: _servings,
            ingredients: items,
          );
      if (!mounted) return;
      Navigator.pop(context, created);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _toast(e.message);
    }
  }

  /// 지정하지 않은 재료를 남겨둔 채 저장할 때 한 번 물어본다 — 조용히 빠지면 안 된다
  Future<bool> _confirmSkip() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('지정하지 않은 재료가 있어요'),
        content: Text('재료를 지정하지 않은 $_attentionCount건은 이 요리에서 제외돼요. 계속할까요?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('돌아가기')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('계속')),
        ],
      ),
    );
    return ok ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_master?.name ?? widget.name)),
      body: _buildBody(),
      bottomNavigationBar: _loading || _error != null ? null : _buildSaveBar(),
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
    return ListView(
      children: [
        _buildHeader(),
        if (_attentionCount > 0) _buildAttentionBanner(),
        const Divider(height: 1),
        ..._rows.map(_buildRow),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildHeader() {
    final master = _master!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(master.name, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text([
            master.category,
            if (master.cookWay != null && master.cookWay!.isNotEmpty) master.cookWay!,
            if (master.kcal1p != null) '${master.kcal1p!.round()}kcal',
          ].join(' · ')),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  '레시피는 1인분 기준이에요. 우리 집 기준 인분으로 저장할 수 있어요.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              ServingsStepper(
                servings: _servings,
                onChanged: (v) => setState(() => _servings = v),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttentionBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '재료 지정이 필요한 항목이 $_attentionCount건 있어요. '
              '탭해서 우리 재료를 고르거나 제외해주세요.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(MappingRow row) {
    final scheme = Theme.of(context).colorScheme;
    final Widget status;
    final List<Widget> actions;

    if (row.needsIngredient) {
      final attention = row.needsAttention;
      status = Text(
        attention ? '재료 지정 필요' : '제외됨 (재료 미지정)',
        style: TextStyle(
          color: attention ? scheme.error : Colors.grey,
          fontWeight: attention ? FontWeight.bold : null,
        ),
      );
      actions = [
        TextButton(onPressed: () => _assign(row), child: const Text('재료 지정')),
        if (attention)
          TextButton(
            onPressed: () => setState(() => row.exclude()),
            child: const Text('제외'),
          ),
      ];
    } else if (row.included) {
      status = Text(
        '${row.ingredientName} · ${formatQuantity(row.quantity!)}${row.unitLabel}',
        style: const TextStyle(fontWeight: FontWeight.bold),
      );
      actions = [
        TextButton(onPressed: () => _editQuantity(row), child: const Text('수량 수정')),
        TextButton(onPressed: () => _assign(row), child: const Text('재료 변경')),
        TextButton(
          onPressed: () => setState(() => row.exclude()),
          child: const Text('제외'),
        ),
      ];
    } else {
      // 재료는 정해졌지만 빠진 줄 — 원문에 수량이 없거나(단위 축이 다르거나) 사용자가 제외했다
      final noQuantity = row.quantity == null;
      status = Text(
        '${row.ingredientName} · ${noQuantity ? '제외됨 (수량 없음)' : '제외됨'}',
        style: const TextStyle(color: Colors.grey),
      );
      actions = [
        if (noQuantity)
          TextButton(onPressed: () => _editQuantity(row), child: const Text('수량 넣고 포함'))
        else
          TextButton(
            onPressed: () => setState(() => row.include()),
            child: const Text('다시 포함'),
          ),
        TextButton(onPressed: () => _assign(row), child: const Text('재료 변경')),
      ];
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                row.included
                    ? Icons.check_circle
                    : row.needsAttention
                        ? Icons.error_outline
                        : Icons.remove_circle_outline,
                size: 18,
                color: row.included
                    ? StatusColors.secured
                    : row.needsAttention
                        ? scheme.error
                        : Colors.grey,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 원문은 항상 보여준다 — 매핑이 맞는지 판단할 근거다
                    Text(row.source.rawText),
                    const SizedBox(height: 2),
                    status,
                  ],
                ),
              ),
            ],
          ),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: actions),
          const Divider(height: 1),
        ],
      ),
    );
  }

  Widget _buildSaveBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  height: 20, width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text('요리 등록 (재료 $_includedCount개)'),
        ),
      ),
    );
  }
}
