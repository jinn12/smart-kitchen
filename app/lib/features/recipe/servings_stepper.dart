import 'package:flutter/material.dart';

/// 기준 인분 입력 (D-015). 1 미만은 서버가 400으로 막는다.
/// 여기서 정한 인분이 나중에 식단 계획의 환산 기준이 된다 (필요량 = 재료량 × 계획인분 ÷ 기준인분)
class ServingsStepper extends StatelessWidget {
  const ServingsStepper({super.key, required this.servings, required this.onChanged});

  final int servings;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('기준 인분', style: Theme.of(context).textTheme.bodySmall),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: servings > 1 ? () => onChanged(servings - 1) : null,
              tooltip: '줄이기',
            ),
            Text('$servings', style: Theme.of(context).textTheme.titleMedium),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => onChanged(servings + 1),
              tooltip: '늘리기',
            ),
          ],
        ),
      ],
    );
  }
}
