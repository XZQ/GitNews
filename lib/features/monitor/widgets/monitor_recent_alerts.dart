import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/section_header.dart';
import '../application/monitor_alert_state_controller.dart';
import '../domain/entities.dart';
import 'monitor_alert_list_tile.dart';

class MonitorRecentAlerts extends ConsumerWidget {
  const MonitorRecentAlerts({required this.alerts, super.key});

  final List<AlertEntity> alerts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = alerts.where((alert) => !alert.isRead).length;
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xs,
            ),
            child: SectionHeader(
              title: '最近告警',
              subtitle: unreadCount == 0 ? '当前可见告警均已处理' : '$unreadCount 条未读，需要关注',
              trailing: TextButton.icon(
                onPressed: alerts.isEmpty || unreadCount == 0
                    ? null
                    : () => ref.read(monitorAlertEventsProvider.notifier).markAllRead(alerts.map((alert) => alert.id).whereType<String>()),
                icon: const Icon(Icons.done_all_rounded, size: 16),
                label: const Text('全部已读'),
              ),
              onTap: () => context.go('/monitor/alerts'),
            ),
          ),
          if (alerts.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: EmptyView(
                icon: Icons.notifications_off_outlined,
                message: '没有匹配的告警',
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

class MonitorAlertRow extends ConsumerWidget {
  const MonitorAlertRow({required this.alert, super.key});

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
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
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
              child: Column(
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
                  Text(
                    monitorAlertMetricLabel(context, alert),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
                Text(
                  alert.time,
                  style: AppTypography.labelSmall.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.xs),
            Tooltip(
              message: l10n.tr(isRead ? 'a11y.mark_unread' : 'a11y.mark_read'),
              child: IconButton(
                visualDensity: VisualDensity.compact,
                iconSize: 18,
                onPressed: alert.id == null ? null : () => ref.read(monitorAlertEventsProvider.notifier).toggleRead(alert.id!),
                icon: Icon(
                  isRead ? Icons.notifications_active_outlined : Icons.done_outlined,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
