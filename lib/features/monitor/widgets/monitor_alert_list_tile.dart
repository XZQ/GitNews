import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../application/monitor_alert_state_controller.dart';
import '../domain/entities.dart';
import '../domain/monitor_rule.dart';

class MonitorAlertListTile extends ConsumerWidget {
  const MonitorAlertListTile({required this.alert, super.key});

  final AlertEntity alert;

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
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _accent();
    final isRead = alert.isRead;
    return InkWell(
      onTap: () {
        final id = alert.id;
        if (id != null) {
          ref.read(monitorAlertEventsProvider.notifier).markRead(id);
        }
        context.go(
          '/project/detail/${Uri.encodeComponent(alert.repoFullName)}',
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: AppSpacing.xxl,
              height: AppSpacing.xxl,
              decoration: BoxDecoration(
                color: color.withValues(alpha: isRead ? 0.08 : 0.14),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(_icon(), color: color, size: 18),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _AlertText(alert: alert, color: color, isRead: isRead),
            ),
            const SizedBox(width: AppSpacing.md),
            _AlertValue(alert: alert, color: color),
            const SizedBox(width: AppSpacing.xs),
            _ReadButton(alert: alert, isRead: isRead),
            _ArchiveButton(alert: alert),
          ],
        ),
      ),
    );
  }
}

class _AlertText extends StatelessWidget {
  const _AlertText({
    required this.alert,
    required this.color,
    required this.isRead,
  });

  final AlertEntity alert;
  final Color color;
  final bool isRead;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (!isRead) ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
              const SizedBox(width: AppSpacing.xs2),
            ],
            Expanded(
              child: Text(
                alert.repoFullName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.titleSmall.copyWith(
                  color: isRead ? colors.onSurfaceVariant : colors.onSurface,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          monitorAlertMetricLabel(context, alert),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.bodySmall.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _AlertValue extends StatelessWidget {
  const _AlertValue({required this.alert, required this.color});

  final AlertEntity alert;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          alert.value,
          style: AppTypography.labelMedium.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          alert.time,
          style: AppTypography.labelSmall.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ReadButton extends ConsumerWidget {
  const _ReadButton({required this.alert, required this.isRead});

  final AlertEntity alert;
  final bool isRead;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Tooltip(
      message: l10n.tr(isRead ? 'a11y.mark_unread' : 'a11y.mark_read'),
      child: IconButton(
        visualDensity: VisualDensity.compact,
        iconSize: 18,
        onPressed: alert.id == null ? null : () => ref.read(monitorAlertEventsProvider.notifier).toggleRead(alert.id!),
        icon: Icon(
          isRead ? Icons.mark_email_unread_outlined : Icons.mark_email_read_outlined,
        ),
      ),
    );
  }
}

class _ArchiveButton extends ConsumerWidget {
  const _ArchiveButton({required this.alert});

  final AlertEntity alert;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Tooltip(
      message: l10n.tr('a11y.archive'),
      child: IconButton(
        visualDensity: VisualDensity.compact,
        iconSize: 18,
        onPressed: alert.id == null ? null : () => ref.read(monitorAlertEventsProvider.notifier).archive(alert.id!),
        icon: const Icon(Icons.archive_outlined),
      ),
    );
  }
}

List<AlertEntity> filterAlertsByState(
  List<AlertEntity> alerts,
  MonitorAlertFilter filter,
) {
  return switch (filter) {
    MonitorAlertFilter.all => alerts,
    MonitorAlertFilter.unread => [
        for (final alert in alerts)
          if (!alert.isRead) alert,
      ],
    MonitorAlertFilter.important => [
        for (final alert in alerts)
          if (alert.severity == AlertSeverity.warning || alert.severity == AlertSeverity.danger) alert,
      ],
  };
}

String monitorAlertMetricLabel(BuildContext context, AlertEntity alert) {
  final l10n = AppLocalizations.of(context);
  final key = switch (alert.ruleId ?? alert.metric) {
    MonitorRuleIds.starDailyDelta => 'monitor.rule.star_growth',
    MonitorRuleIds.starDailyRate => 'monitor.rule.daily_growth',
    MonitorRuleIds.forkDailyDelta => 'monitor.rule.fork_growth',
    MonitorRuleIds.issueHeatRatio => 'monitor.rule.discuss_heat',
    _ => null,
  };
  return key == null ? alert.metric : l10n.tr(key);
}
