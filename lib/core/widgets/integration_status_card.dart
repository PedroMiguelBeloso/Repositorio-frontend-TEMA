import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import 'status_chip.dart';

class IntegrationStatusCard extends StatelessWidget {
  const IntegrationStatusCard({
    super.key,
    required this.sourceLabel,
    required this.statusLabel,
    required this.tone,
    this.checkedAtLabel,
    this.message,
  });

  final String sourceLabel;
  final String statusLabel;
  final StatusTone tone;
  final String? checkedAtLabel;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final detail = message?.trim();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(sourceLabel, style: theme.textTheme.titleMedium),
                StatusChip(label: statusLabel, tone: tone),
              ],
            ),
            if (checkedAtLabel != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                'Última comprobación: $checkedAtLabel',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            if (detail != null && detail.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(detail, style: theme.textTheme.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }
}