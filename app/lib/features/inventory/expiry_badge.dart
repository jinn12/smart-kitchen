import 'package:flutter/material.dart';
import 'inventory_models.dart';

/// D-배지 (R-5, D-020).
/// 경과 = 빨강 "만료", D-3~D-0 = 주황 "D-n", 그 외는 회색 또는 표시 없음.
class ExpiryBadge extends StatelessWidget {
  const ExpiryBadge({super.key, required this.status, required this.dday});

  final ExpiryStatus status;
  final int? dday;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      ExpiryStatus.expired => ('만료', Colors.red),
      ExpiryStatus.expiring => ('D-${dday ?? 0}', Colors.orange),
      ExpiryStatus.normal => (dday != null ? 'D-$dday' : '-', Colors.grey),
      ExpiryStatus.none => ('유통기한 없음', Colors.grey),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
