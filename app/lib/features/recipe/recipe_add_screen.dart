import 'package:flutter/material.dart';
import 'recipe_manual_add_screen.dart';
import 'recipe_master_search_screen.dart';
import 'recipe_models.dart';

/// S-23 요리 등록 — 두 갈래 중 하나를 고르는 진입 화면.
/// 등록에 성공하면 만들어진 요리를 그대로 위로 돌려준다(S-21이 강조 표시에 쓴다).
class RecipeAddScreen extends StatelessWidget {
  const RecipeAddScreen({super.key});

  Future<void> _go(BuildContext context, Widget screen) async {
    final created = await Navigator.of(context).push<RecipeDetail>(
      MaterialPageRoute(builder: (_) => screen),
    );
    if (created == null || !context.mounted) return;
    Navigator.pop(context, created);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('요리 등록')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '어떻게 등록할까요?',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          _ChoiceCard(
            icon: Icons.menu_book_outlined,
            title: '레시피에서 찾기',
            description: '공공 레시피를 검색해 가져옵니다. 재료가 우리 식재료와 맞는지 확인한 뒤 저장해요.',
            onTap: () => _go(context, const RecipeMasterSearchScreen()),
          ),
          const SizedBox(height: 12),
          _ChoiceCard(
            icon: Icons.edit_outlined,
            title: '직접 입력',
            description: '이름과 인분을 정하고 재료를 하나씩 담습니다.',
            onTap: () => _go(context, const RecipeManualAddScreen()),
          ),
        ],
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            )),
                    const SizedBox(height: 4),
                    Text(description, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
