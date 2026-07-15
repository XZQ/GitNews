import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_card.dart';
import '../domain/entities.dart';

class MonitorStatusRow extends StatelessWidget {
  const MonitorStatusRow({required this.stats, super.key});

  final MonitorStats stats;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
            child: _MonitorStatusCard(
          label: '监控仓库',
          value: '${stats.monitoredCount}',
          delta: _formatDelta(stats.monitoredDelta),
          icon: Icons.visibility_outlined,
          color: colors.primary,
        )),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
            child: _MonitorStatusCard(
          label: '未读告警',
          value: '${stats.unreadAlertCount}',
          delta: _formatDelta(stats.unreadAlertDelta),
          icon: Icons.error_outline,
          color: AppColors.warning,
        )),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
            child: _MonitorStatusCard(
          label: '今日触发',
          value: '${stats.triggeredTodayCount}',
          delta: _formatDelta(stats.triggeredTodayDelta),
          icon: Icons.bolt_rounded,
          color: AppColors.info,
        )),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
            child: _MonitorStatusCard(
          label: '告警总数',
          value: '${stats.totalAlertCount}',
          delta: _formatDelta(stats.totalAlertDelta),
          icon: Icons.history_rounded,
          color: AppColors.success,
        ))
      ],
    );
  }

  String _formatDelta(int value) {
    if (value > 0) {
      return '+$value';
    }
    return '$value';
  }
}

class _MonitorStatusCard extends StatelessWidget {
  const _MonitorStatusCard({
    required this.label,
    required this.value,
    required this.delta,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final String delta;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: AppSpacing.xs),
            Expanded(child: Text(label, style: AppTypography.labelSmall.copyWith(color: colors.onSurfaceVariant)))
          ]),
          const SizedBox(height: AppSpacing.sm2),
          Text(value, style: AppTypography.headlineMedium.copyWith(color: colors.onSurface)),
          const SizedBox(height: AppSpacing.xxs),
          Text(delta, style: AppTypography.labelSmall.copyWith(color: AppColors.success, fontWeight: FontWeight.w600))
        ],
      ),
    );
  }
}
