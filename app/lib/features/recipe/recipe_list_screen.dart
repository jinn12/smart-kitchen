import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api_exception.dart';
import '../../core/empty_state.dart';
import 'recipe_add_screen.dart';
import 'recipe_api.dart';
import 'recipe_detail_screen.dart';
import 'recipe_models.dart';

/// S-21 내 요리 목록. 요리 탭의 시작 화면.
class RecipeListScreen extends StatefulWidget {
  const RecipeListScreen({super.key});

  @override
  State<RecipeListScreen> createState() => RecipeListScreenState();
}

class RecipeListScreenState extends State<RecipeListScreen> {
  bool _loading = true;
  String? _error;
  List<RecipeSummary> _recipes = const [];

  /// 등록 직후 목록에서 찾아보기 쉽도록 잠깐 강조한다
  int? _highlightId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// 탭으로 돌아올 때마다 셸이 부른다 — 재고가 바뀌면 "지금 가능" 배지도 달라진다
  void reload() {
    if (!_loading) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final recipes = await context.read<RecipeApi>().list();
      if (!mounted) return;
      setState(() {
        _recipes = recipes;
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

  void _openDetail(RecipeSummary recipe) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RecipeDetailScreen(recipeId: recipe.id, name: recipe.name),
      ),
    );
  }

  Future<void> _openAdd() async {
    final created = await Navigator.of(context).push<RecipeDetail>(
      MaterialPageRoute(builder: (_) => const RecipeAddScreen()),
    );
    if (created == null || !mounted) return;
    setState(() => _highlightId = created.id);
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('${created.name}을(를) 등록했습니다')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('요리'),
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
        label: const Text('요리 등록'),
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
    if (_recipes.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: [
            EmptyState(
              icon: Icons.restaurant_outlined,
              title: '우리집 메뉴판을 만들어보세요',
              description: '공공 레시피에서 찾거나 직접 입력할 수 있어요.\n등록해 두면 식단 계획에서 바로 고를 수 있어요.',
              actionLabel: '요리 등록하기',
              onAction: _openAdd,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 88), // FAB에 가리지 않도록
        itemCount: _recipes.length,
        itemBuilder: (_, i) => _buildCard(_recipes[i]),
      ),
    );
  }

  Widget _buildCard(RecipeSummary recipe) {
    final highlighted = recipe.id == _highlightId;
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      color: highlighted
          ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4)
          : null,
      child: ListTile(
        title: Text(recipe.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('${recipe.servings}인분 · 재료 ${recipe.ingredientCount}개'),
              _SourceChip(source: recipe.source),
              if (recipe.cookableNow) const CookableBadge(),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _openDetail(recipe),
      ),
    );
  }
}

class _SourceChip extends StatelessWidget {
  const _SourceChip({required this.source});

  final RecipeSource source;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        source.label,
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}

/// cookableNow 배지. 등록 분량 기준이지 인분 환산이 아니다 (D-024)
class CookableBadge extends StatelessWidget {
  const CookableBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        '지금 가능',
        style: TextStyle(
          color: Colors.green,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
