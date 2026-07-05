import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/skeleton.dart';
import '../application/monitor_alert_state_controller.dart';
import '../application/monitor_providers.dart';
import '../domain/entities.dart';
import '../widgets/monitor_alert_list_tile.dart';

class MonitorAlertsPage extends ConsumerWidget {
  const MonitorAlertsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(monitorDigestProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('告警列表'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/monitor'),
        ),
      ),
      body: state.when(
        data: (digest) {
          final alertState = ref.watch(monitorAlertStateControllerProvider);
          final visibleAlerts = alertState.visibleAlerts(digest.alerts);
          if (digest.alerts.isEmpty) {
            return const EmptyView(
              icon: Icons.notifications_none_rounded,
              message: '最近 24 小时暂无告警',
            );
          }
          return ResponsiveLayout(
            compact: (_) => _Body(
              alerts: visibleAlerts,
              rawAlerts: digest.alerts,
            ),
            medium: (_) => CenteredContent(
              child: _Body(alerts: visibleAlerts, rawAlerts: digest.alerts),
            ),
            expanded: (_) => CenteredContent(
              child: _Body(alerts: visibleAlerts, rawAlerts: digest.alerts),
            ),
          );
        },
        loading: () => const _AlertsSkeleton(),
        error: (error, stack) => ErrorView(
          error: error.asAppException(stack),
          onRetry: () => ref.invalidate(monitorDigestProvider),
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({
    required this.alerts,
    required this.rawAlerts,
  });

  final List<AlertEntity> alerts;
  final List<AlertEntity> rawAlerts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertState = ref.watch(monitorAlertStateControllerProvider);
    final filter = ref.watch(monitorAlertFilterProvider);
    final filteredAlerts = filterAlertsByState(alerts, alertState, filter);
    final unreadCount = alertState.unreadCount(alerts);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      children: [
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.xs,
                ),
                child: SectionHeader(
                  title: '所有告警',
                  subtitle:
                      '可见 ${alerts.length} 条 · 未读 $unreadCount 条 · 已归档 ${rawAlerts.length - alerts.length} 条',
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xs,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SegmentedButton<MonitorAlertFilter>(
                      segments: const [
                        ButtonSegment(
                          value: MonitorAlertFilter.all,
                          label: Text('全部'),
                          icon: Icon(Icons.inbox_outlined),
                        ),
                        ButtonSegment(
                          value: MonitorAlertFilter.unread,
                          label: Text('未读'),
                          icon: Icon(Icons.mark_email_unread_outlined),
                        ),
                        ButtonSegment(
                          value: MonitorAlertFilter.important,
                          label: Text('重点'),
                          icon: Icon(Icons.priority_high_rounded),
                        ),
                      ],
                      selected: {filter},
                      onSelectionChanged: (values) => ref
                          .read(monitorAlertFilterProvider.notifier)
                          .state = values.single,
                    ),
                    TextButton.icon(
                      onPressed: unreadCount == 0
                          ? null
                          : () => ref
                              .read(
                                monitorAlertStateControllerProvider.notifier,
                              )
                              .markAllRead(alerts),
                      icon: const Icon(Icons.done_all_rounded),
                      label: const Text('全部已读'),
                    ),
                    TextButton.icon(
                      onPressed: alerts.any(alertState.isRead)
                          ? () => ref
                              .read(
                                monitorAlertStateControllerProvider.notifier,
                              )
                              .archiveRead(alerts)
                          : null,
                      icon: const Icon(Icons.cleaning_services_outlined),
                      label: const Text('清空已读'),
                    ),
                    TextButton.icon(
                      onPressed: rawAlerts.length == alerts.length
                          ? null
                          : () => ref
                              .read(
                                monitorAlertStateControllerProvider.notifier,
                              )
                              .restoreAll(),
                      icon: const Icon(Icons.restore_rounded),
                      label: const Text('恢复归档'),
                    ),
                  ],
                ),
              ),
              if (filteredAlerts.isEmpty)
                const Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.xl,
                  ),
                  child: EmptyView(
                    icon: Icons.notifications_off_outlined,
                    message: '当前筛选下没有告警',
                  ),
                ),
              for (var i = 0; i < filteredAlerts.length; i++) ...[
                if (i != 0) const Divider(height: 1),
                MonitorAlertListTile(alert: filteredAlerts[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _AlertsSkeleton extends StatelessWidget {
  const _AlertsSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      children: const [
        Skeleton(height: 72),
        SizedBox(height: AppSpacing.md),
        Skeleton(height: 72),
        SizedBox(height: AppSpacing.md),
        Skeleton(height: 72),
        SizedBox(height: AppSpacing.md),
        Skeleton(height: 72),
      ],
    );
  }
}
