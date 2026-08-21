import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api_exception.dart';
import '../../core/date_utils.dart';
import '../../core/empty_state.dart';
import 'meal_plan_add_flow.dart';
import 'meal_plan_api.dart';
import 'meal_plan_models.dart';

/// S-31 주간 식탁. 오늘부터 7일을 기본으로 보여주고 주 단위로 이동한다.
class MealPlanWeekScreen extends StatefulWidget {
  const MealPlanWeekScreen({super.key});

  @override
  State<MealPlanWeekScreen> createState() => MealPlanWeekScreenState();
}

class MealPlanWeekScreenState extends State<MealPlanWeekScreen> {
  static const _weekLength = 7;

  /// 기본 창(오늘~+6일)에서 몇 주 떨어져 있는지. 0이면 오늘이 포함된 창
  int _weekOffset = 0;

  bool _loading = true;
  String? _error;
  List<MealPlanDay> _days = const [];

  DateTime get _from => today().add(Duration(days: _weekOffset * _weekLength));
  DateTime get _to => _from.add(const Duration(days: _weekLength - 1));

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// 탭으로 돌아왔을 때 셸이 부른다 — 다른 탭에서 바뀐 예약이 바로 보이도록
  void reload() {
    if (!_loading) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final days = await context.read<MealPlanApi>().weekly(from: _from, to: _to);
      if (!mounted) return;
      setState(() {
        _days = days;
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

  void _moveWeek(int delta) {
    setState(() => _weekOffset += delta);
    _load();
  }

  void _goToday() {
    if (_weekOffset == 0) return;
    setState(() => _weekOffset = 0);
    _load();
  }

  Future<void> _openAdd() async {
    final created = await startMealPlanFlow(context);
    if (created == null || !mounted) return;

    // 등록한 날짜가 지금 보고 있는 주 밖이면 그 주로 옮겨 준다
    final offset = created.planDate.difference(today()).inDays ~/ _weekLength;
    setState(() => _weekOffset = offset);
    await _load();
    if (!mounted) return;

    final shopping = created.addedToShoppingCount;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      duration: const Duration(seconds: 4),
      content: Text(
        '재고가 예약되었습니다 · 냉장고 탭의 가용 재고에 반영됨'
        '${shopping > 0 ? ' · 장보기에 $shopping건 담김' : ''}',
      ),
    ));
  }

  Future<void> _cancel(MealSummary meal) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('계획 취소'),
        content: Text('${meal.recipeName} 계획을 취소할까요?\n예약해 둔 재고가 다시 가용으로 돌아갑니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('닫기')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('계획 취소')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      final result = await context.read<MealPlanApi>().cancel(meal.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('계획을 취소했습니다 · 재료 ${result.releasedIngredientCount}개의 예약을 풀었습니다'),
      ));
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('식탁'),
        actions: [
          if (_weekOffset != 0)
            TextButton(onPressed: _goToday, child: const Text('오늘')),
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
        label: const Text('계획 등록'),
      ),
      body: Column(
        children: [
          _buildWeekBar(),
          const Divider(height: 1),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildWeekBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => _moveWeek(-1),
            icon: const Icon(Icons.chevron_left),
            tooltip: '이전 주',
          ),
          Text(
            '${formatShortDate(_from)} – ${formatShortDate(_to)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          IconButton(
            onPressed: () => _moveWeek(1),
            icon: const Icon(Icons.chevron_right),
            tooltip: '다음 주',
          ),
        ],
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
    // 이 주에 계획이 하나도 없으면 "계획 없음" 일곱 줄 대신 다음 행동을 안내한다
    final isEmptyWeek = _days.every((d) => d.meals.isEmpty);
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 88), // FAB에 가리지 않도록
        children: isEmptyWeek
            ? [
                EmptyState(
                  icon: Icons.calendar_month_outlined,
                  title: _weekOffset == 0
                      ? '이번 주 식단을 짜볼까요?'
                      : '이 주에는 세워둔 계획이 없어요',
                  description: '요리를 고르고 날짜만 정하면, 부족한 재료를 미리 알려드려요.',
                  actionLabel: '계획 등록하기',
                  onAction: _openAdd,
                ),
              ]
            : _days.map(_buildDay).toList(),
      ),
    );
  }

  Widget _buildDay(MealPlanDay day) {
    final relative = relativeDayLabel(day.date);
    final isToday = isSameDay(day.date, today());
    final empty = day.meals.isEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                formatDayLabel(day.date),
                style: TextStyle(
                  fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                  // 계획 없는 날은 옅게 — 있는 날에 눈이 먼저 가도록
                  color: empty ? Colors.grey : null,
                ),
              ),
              if (relative != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(relative, style: Theme.of(context).textTheme.labelSmall),
                ),
              ],
            ],
          ),
          if (empty)
            const Padding(
              padding: EdgeInsets.fromLTRB(2, 4, 0, 4),
              child: Text('계획 없음', style: TextStyle(color: Colors.grey, fontSize: 13)),
            )
          else
            ...day.meals.map(_buildMealCard),
        ],
      ),
    );
  }

  Widget _buildMealCard(MealSummary meal) {
    final confirmed = meal.status == MealPlanStatus.confirmed;
    return Card(
      margin: const EdgeInsets.only(top: 6),
      child: ListTile(
        dense: true,
        leading: Container(
          width: 44,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(meal.mealType.label),
        ),
        title: Text(meal.recipeName),
        subtitle: Text('${meal.servings}인분'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StatusChip(status: meal.status),
            // 확정된 계획은 이미 차감이 끝나 되돌릴 수 없다 (R-6)
            if (!confirmed)
              PopupMenuButton<String>(
                onSelected: (_) => _cancel(meal),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'cancel', child: Text('계획 취소')),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final MealPlanStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      MealPlanStatus.confirmed => Colors.green,
      MealPlanStatus.planned => Colors.blueGrey,
      MealPlanStatus.canceled => Colors.grey,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
