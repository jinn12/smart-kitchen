import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api_exception.dart';
import '../ingredient/ingredient_models.dart' show formatQuantity;
import 'recipe_api.dart';
import 'recipe_list_screen.dart' show CookableBadge;
import 'recipe_models.dart';

/// S-22 요리 상세. 재료별로 필요량과 가용량을 나란히 보여준다.
class RecipeDetailScreen extends StatefulWidget {
  const RecipeDetailScreen({super.key, required this.recipeId, required this.name});

  final int recipeId;

  /// 목록에서 넘겨받은 이름 — 로딩 중에도 제목을 비우지 않기 위해
  final String name;

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  bool _loading = true;
  String? _error;
  RecipeDetail? _detail;

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
      final detail = await context.read<RecipeApi>().detail(widget.recipeId);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_detail?.name ?? widget.name)),
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
    final detail = _detail!;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        children: [
          _buildHeader(detail),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('재료 ${detail.ingredients.length}개',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          ...detail.ingredients.map(_buildIngredientTile),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeader(RecipeDetail detail) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(detail.name,
                    style: Theme.of(context).textTheme.titleLarge),
              ),
              if (detail.cookableNow) const CookableBadge(),
            ],
          ),
          const SizedBox(height: 8),
          Text('${detail.servings}인분 · ${detail.source.label}'),
          const SizedBox(height: 4),
          // D-024 — 배지·부족 판정은 등록 분량 그대로다. 인분 환산은 식단 계획의 몫
          Text(
            detail.cookableNow
                ? '등록 분량(${detail.servings}인분) 기준으로 지금 만들 수 있어요.'
                : '등록 분량(${detail.servings}인분) 기준으로 부족한 재료가 있어요.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientTile(RecipeIngredient item) {
    final unit = item.unitLabel;
    final need = '${formatQuantity(item.quantity)}$unit';

    // sufficient == null은 잔량 관리를 하지 않는 재료 (R-4) — 판단 자체를 하지 않는다
    if (item.sufficient == null) {
      return ListTile(
        title: Text(item.name, style: const TextStyle(color: Colors.grey)),
        subtitle: Text('필요 $need · 계량 제외',
            style: const TextStyle(color: Colors.grey)),
        trailing: const Text('계량 제외', style: TextStyle(color: Colors.grey)),
      );
    }

    final short = item.sufficient == false;
    final color = short ? Theme.of(context).colorScheme.error : null;
    return ListTile(
      title: Text(
        item.name,
        style: TextStyle(color: color, fontWeight: short ? FontWeight.bold : null),
      ),
      subtitle: Text(
        '필요 $need · 가용 ${formatQuantity(item.availableQuantity)}$unit',
        style: TextStyle(color: color),
      ),
      trailing: short
          ? Text(
              '${formatQuantity(item.quantity - item.availableQuantity)}$unit 부족',
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            )
          : const Icon(Icons.check, color: Colors.green, size: 20),
    );
  }
}
