import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api_exception.dart';
import 'recipe_api.dart';
import 'recipe_mapping_screen.dart';
import 'recipe_models.dart';

/// S-23 "레시피에서 찾기" — 공공 레시피 검색 (API-33).
/// 1,100여 건이라 20건씩 나눠 받고 더보기로 이어 붙인다.
class RecipeMasterSearchScreen extends StatefulWidget {
  const RecipeMasterSearchScreen({super.key});

  @override
  State<RecipeMasterSearchScreen> createState() => _RecipeMasterSearchScreenState();
}

class _RecipeMasterSearchScreenState extends State<RecipeMasterSearchScreen> {
  static const _pageSize = 20;

  final _keyword = TextEditingController();
  final _scroll = ScrollController();
  String? _category;

  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  int _totalCount = 0;
  int _nextPage = 0;
  final List<RecipeMasterSummary> _items = [];

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _search();
  }

  @override
  void dispose() {
    _keyword.dispose();
    _scroll.dispose();
    super.dispose();
  }

  bool get _hasMore => _items.length < _totalCount;

  void _onScroll() {
    // 바닥 근처에 닿으면 다음 장을 미리 당겨온다 (더보기 버튼도 함께 둔다)
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  /// 첫 장부터 다시 (검색어·카테고리가 바뀔 때)
  Future<void> _search() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await _fetch(0);
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(page.items);
        _totalCount = page.totalCount;
        _nextPage = 1;
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

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final page = await _fetch(_nextPage);
      if (!mounted) return;
      setState(() {
        _items.addAll(page.items);
        _totalCount = page.totalCount;
        _nextPage += 1;
        _loadingMore = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<RecipeMasterPage> _fetch(int page) {
    return context.read<RecipeApi>().searchMasters(
          keyword: _keyword.text.trim(),
          category: _category,
          page: page,
          size: _pageSize,
        );
  }

  Future<void> _openMapping(RecipeMasterSummary master) async {
    final created = await Navigator.of(context).push<RecipeDetail>(
      MaterialPageRoute(
        builder: (_) => RecipeMappingScreen(masterId: master.id, name: master.name),
      ),
    );
    if (created == null || !mounted) return;
    Navigator.pop(context, created);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('레시피에서 찾기')),
      body: Column(
        children: [
          _buildSearchBar(),
          const Divider(height: 1),
          Expanded(child: _buildResults()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Column(
        children: [
          TextField(
            controller: _keyword,
            decoration: InputDecoration(
              labelText: '레시피 검색',
              hintText: '예: 된장',
              suffixIcon: IconButton(
                icon: const Icon(Icons.search),
                onPressed: _search,
              ),
            ),
            onSubmitted: (_) => _search(),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: const Text('전체'),
                    selected: _category == null,
                    onSelected: (_) {
                      setState(() => _category = null);
                      _search();
                    },
                  ),
                ),
                ...recipeMasterCategories.map((c) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(c),
                        selected: _category == c,
                        onSelected: (_) {
                          setState(() => _category = c);
                          _search();
                        },
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!),
            const SizedBox(height: 12),
            FilledButton(onPressed: _search, child: const Text('다시 시도')),
          ],
        ),
      );
    }
    if (_items.isEmpty) {
      return const Center(child: Text('검색 결과가 없습니다.'));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('총 $_totalCount건 · ${_items.length}건 표시',
                style: Theme.of(context).textTheme.bodySmall),
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            itemCount: _items.length + 1,
            itemBuilder: (_, i) {
              if (i == _items.length) return _buildFooter();
              final m = _items[i];
              return ListTile(
                title: Text(m.name),
                subtitle: Text([
                  m.category,
                  if (m.cookWay != null && m.cookWay!.isNotEmpty) m.cookWay!,
                  if (m.kcal1p != null) '${m.kcal1p!.round()}kcal',
                ].join(' · ')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openMapping(m),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    if (_loadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (!_hasMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: Text('마지막입니다', style: TextStyle(color: Colors.grey))),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: OutlinedButton(onPressed: _loadMore, child: const Text('더보기')),
    );
  }
}
