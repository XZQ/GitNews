import 'package:flutter/material.dart';

import '../../../core/demo_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/section_header.dart';

class MonitorRecentAlerts extends StatelessWidget {
  const MonitorRecentAlerts({required this.alerts, super.key});

  final List<DemoAlert> alerts;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xs,
            ),
            child: SectionHeader(
              title: '最近告警',
              subtitle: '今日与昨日告警流',
            ),
          ),
          for (var i = 0; i < alerts.length; i++) ...[
            if (i != 0) const Divider(height: 1),
            MonitorAlertRow(alert: alerts[i]),
          ],
        ],
      ),
    );
  }
}

class MonitorAlertRow extends StatelessWidget {
  const MonitorAlertRow({required this.alert, super.key});

  final DemoAlert alert;

  Color _accent() {
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
      AlertSeverity.danger => Icons.error_outline,
      AlertSeverity.info => Icons.info_outline,
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = _accent();
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(_icon(), color: color, size: 18),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alert.repo, style: AppTypography.titleSmall),
                Text(
                  alert.metric,
                  style: AppTypography.bodySmall.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            alert.value,
            style: AppTypography.labelMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            alert.time,
            style: AppTypography.labelSmall.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
