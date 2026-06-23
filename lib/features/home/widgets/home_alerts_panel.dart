import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/demo_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/section_header.dart';

/// 监控告警面板(手机首页 + 桌面右栏共用)。
class HomeAlertsPanel extends StatelessWidget {
  const HomeAlertsPanel({
    this.showHeader = true,
    this.maxItems = 4,
    super.key,
  });

  final bool showHeader;
  final int maxItems;

  @override
  Widget build(BuildContext context) {
    final items = DemoData.alerts.take(maxItems).toList();
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          if (showHeader)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xs,
              ),
              child: SectionHeader(
                title: '监控告警',
                subtitle: '未读 ${items.length} 条',
                onTap: () => context.go('/monitor'),
              ),
            ),
          for (var i = 0; i < items.length; i++) ...[
            if (i != 0) const Divider(height: 1),
            _AlertTile(alert: items[i]),
          ],
        ],
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({required this.alert});
  final DemoAlert alert;

  Color _accent(BuildContext c) {
    return switch (alert.severity) {
      AlertSeverity.success => AppColors.success,
      AlertSeverity.warning => AppColors.warning,
      AlertSeverity.danger => AppColors.danger,
      AlertSeverity.info => AppColors.info,
    };
  }

  IconData _icon() {
    return switch (alert.severity) {
      AlertSeverity.success => Icons.trending_up_rounded,
      AlertSeverity.warning => Icons.warning_amber_rounded,
      AlertSeverity.danger => Icons.error_outline_rounded,
      AlertSeverity.info => Icons.info_outline_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = _accent(context);
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => context.go('/monitor'),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_icon(), size: 18, color: color),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.repo,
                    style: AppTypography.titleSmall.copyWith(
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    alert.metric,
                    style: AppTypography.bodySmall.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  alert.value,
                  style: AppTypography.labelMedium.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  alert.time,
                  style: AppTypography.labelSmall.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
