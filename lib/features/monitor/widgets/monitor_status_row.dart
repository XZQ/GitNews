import 'package:flutter/material.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/adaptive_metric_grid.dart';
import '../../../shared/widgets/app_card.dart';
import '../domain/entities.dart';

class MonitorStatusRow extends StatelessWidget {
  const MonitorStatusRow({required this.stats, super.key});

  final MonitorStats stats;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return AdaptiveMetricGrid(
      children: [
        _MonitorStatusCard(
          label: l10n.tr('monitor.status.monitored'),
          value: '${stats.monitoredCount}',
          delta: _formatDelta(stats.monitoredDelta),
          icon: Icons.visibility_outlined,
          color: colors.primary,
        ),
        _MonitorStatusCard(
          label: l10n.tr('monitor.status.unread'),
          value: '${stats.unreadAlertCount}',
          delta: _formatDelta(stats.unreadAlertDelta),
          icon: Icons.error_outline,
          color: AppColors.warning,
        ),
        _MonitorStatusCard(
          label: l10n.tr('monitor.status.triggered_today'),
          value: '${stats.triggeredTodayCount}',
          delta: _formatDelta(stats.triggeredTodayDelta),
          icon: Icons.bolt_rounded,
          color: AppColors.info,
        ),
        _MonitorStatusCard(
          label: l10n.tr('monitor.status.total_alerts'),
          value: '${stats.totalAlertCount}',
          delta: _formatDelta(stats.totalAlertDelta),
          icon: Icons.history_rounded,
          color: AppColors.success,
        ),
      ],
    );
  }

  String? _formatDelta(int value) {
    if (value == 0) {
      return null;
    }
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
    this.delta,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final String? delta;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      label: delta == null ? '$label $value' : '$label $value，变化 $delta',
      child: ExcludeSemantics(
        child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 16),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelSmall.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm2),
              SizedBox(
                width: double.infinity,
                child: FittedBox(
                  alignment: Alignment.centerLeft,
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: AppTypography.headlineMedium.copyWith(color: colors.onSurface),
                  ),
                ),
              ),
              if (delta != null) ...[
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  delta!,
                  style: AppTypography.labelSmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
