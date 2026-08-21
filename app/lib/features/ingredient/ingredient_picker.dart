import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api_exception.dart';
import 'ingredient_api.dart';
import 'ingredient_models.dart';

/// API-10 식재료 검색 UI. S-13(재고 등록)·S-23(요리 등록)·S-41(장보기 수동 추가)이 함께 쓴다.
class IngredientSearchPanel extends StatefulWidget {
  const IngredientSearchPanel({
    super.key,
    required this.onSelect,
    this.isPicked,
    this.belowSearchBar,
    this.allowNonTrackable = true,
  });

  final void Function(IngredientSearchResult) onSelect;

  /// 검색창과 결과 목록 사이에 끼울 영역 (담은 재료 요약 등)
  final Widget? belowSearchBar;

  /// 이미 담긴 재료에 체크 표시를 하기 위한 판정
  final bool Function(IngredientSearchResult)? isPicked;

  /// 잔량 관리를 하지 않는 재료(R-4)를 고를 수 있는지.
  /// 재고 등록은 불가(S-13)지만 요리 재료로는 가능하다 — 판정에서만 빠진다
  final bool allowNonTrackable;

  @override
  State<IngredientSearchPanel> createState() => _IngredientSearchPanelState();
}

class _IngredientSearchPanelState extends State<IngredientSearchPanel> {
  final _keyword = TextEditingController();
  String? _category;
  bool _searching = false;
  String? _error;
  List<IngredientSearchResult> _results = const [];

  @override
  void initState() {
    super.initState();
    _search();
  }

  @override
  void dispose() {
    _keyword.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    setState(() {
      _searching = true;
      _error = null;
    });
    try {
      final results = await context.read<IngredientApi>().search(
            keyword: _keyword.text.trim(),
            category: _category,
          );
      if (!mounted) return;
      setState(() {
        _results = results;
        _searching = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _searching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchBar(),
        if (widget.belowSearchBar != null) widget.belowSearchBar!,
        const Divider(height: 1),
        Expanded(child: _buildResults()),
      ],
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
              labelText: '식재료 검색',
              hintText: '예: 두부',
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
                ...ingredientCategories.map((c) => Padding(
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
    if (_searching) return const Center(child: CircularProgressIndicator());
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
    if (_results.isEmpty) {
      return const Center(child: Text('검색 결과가 없습니다.'));
    }
    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (_, i) {
        final r = _results[i];
        final picked = widget.isPicked?.call(r) ?? false;
        final selectable = widget.allowNonTrackable || r.isTrackable;
        return ListTile(
          title: Text(r.name),
          subtitle: Text(
            '${r.category} · ${r.unitLabel}'
            '${r.isCustom ? ' · 내 재료' : ''}'
            '${r.isTrackable ? '' : ' · 잔량 관리 안 함'}',
          ),
          trailing: picked
              ? const Icon(Icons.check_circle, color: Colors.green)
              : const Icon(Icons.add_circle_outline),
          enabled: selectable,
          onTap: () => widget.onSelect(r),
        );
      },
    );
  }
}

/// 재료 하나를 골라서 돌려주는 화면. 매핑 확인 화면의 "재료 지정"이 쓴다
class IngredientSearchScreen extends StatelessWidget {
  const IngredientSearchScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: IngredientSearchPanel(
        onSelect: (ingredient) => Navigator.pop(context, ingredient),
      ),
    );
  }
}

Future<IngredientSearchResult?> pickIngredient(BuildContext context, {required String title}) {
  return Navigator.of(context).push<IngredientSearchResult>(
    MaterialPageRoute(builder: (_) => IngredientSearchScreen(title: title)),
  );
}

/// 수량 입력 다이얼로그. 단위는 base_unit 고정이라 바꿀 수 없다 (D-004)
Future<num?> askQuantity(
  BuildContext context, {
  required String name,
  required String unitLabel,
  num? initial,
  String? hint,
  String confirmLabel = '확인',
}) {
  final controller = TextEditingController(
      text: initial != null ? formatQuantity(initial) : '');
  return showDialog<num>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(name),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: '수량 ($unitLabel)'),
          ),
          if (hint != null) ...[
            const SizedBox(height: 12),
            Text(hint, style: Theme.of(ctx).textTheme.bodySmall),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
        FilledButton(
          onPressed: () {
            final v = num.tryParse(controller.text.trim());
            if (v == null || v <= 0) return;
            Navigator.pop(ctx, v);
          },
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
}
