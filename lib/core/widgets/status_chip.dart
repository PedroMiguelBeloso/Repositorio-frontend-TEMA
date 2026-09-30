import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

enum StatusTone { success, warning, danger, info, neutral }

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.tone});

  final String label;
  final StatusTone tone;

  Color get _color => switch (tone) {
    StatusTone.success => AppColors.success,
    StatusTone.warning => AppColors.warning,
    StatusTone.danger => AppColors.danger,
    StatusTone.info => AppColors.info,
    StatusTone.neutral => AppColors.textSecondary,
  };

  IconData get _icon => switch (tone) {
    StatusTone.success => Icons.check_circle_outline,
    StatusTone.warning => Icons.warning_amber_outlined,
    StatusTone.danger => Icons.error_outline,
    StatusTone.info => Icons.info_outline,
    StatusTone.neutral => Icons.circle_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final color = _color;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, color: color, size: 14),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
