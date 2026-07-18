import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/breakpoint.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../../shared/widgets/skeleton.dart';
import '../application/monitor_providers.dart';
import '../domain/entities.dart';
import '../domain/monitor_repository.dart';
import '../widgets/monitor_mobile_content.dart';
import '../widgets/monitor_monitored_repos.dart';
import '../widgets/monitor_page_header.dart';
import '../widgets/monitor_recent_alerts.dart';
import '../widgets/monitor_settings_cards.dart';
import '../widgets/monitor_status_row.dart';

/*
*仓库监控主页面。
*
*移动端使用设计稿的四项统计、分组仓库列表和告警卡片；中大屏继续保留检索、规则和通知工作台。
*/
class MonitorPage extends ConsumerWidget {
  const MonitorPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isCompact = Breakpoints.isCompact(context);
    final state = ref.watch(filteredMonitorDigestProvider);
    return Scaffold(
      appBar: isCompact ? AppBar(title: Text(l10n.tr('monitor.title'), style: AppTypography.headlineLarge.copyWith(color: Theme.of(context).colorScheme.onSurface))) : null,
      body: state.when(
        data: (digest) {
          if (digest.isEmpty) {
            return EmptyView(icon: Icons.visibility_off_outlined, message: l10n.tr('monitor.empty'));
          }
          return ResponsiveLayout(
            compact: (_) => MonitorMobileContent(digest: digest),
            medium: (_) => _Desktop(digest: digest),
            expanded: (_) => _Desktop(digest: digest),
          );
        },
        loading: () => const _MonitorSkeleton(),
        error: (error, stack) => ErrorView(error: error.asAppException(stack), onRetry: () => forceRefreshMonitor(ref)),
      ),
    );
  }
}

/* 监控页的中大屏工作台。 */
class _Desktop extends ConsumerWidget {
  const _Desktop({required this.digest});

  final MonitorDigest digest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = ref.watch(monitorSearchQueryProvider).trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MonitorPageHeader(stats: digest.stats),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MonitorStatusRow(stats: digest.stats),
                const SizedBox(height: AppSpacing.lg),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 8, child: MonitorMonitoredRepos(repos: digest.monitoredRepos)),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        flex: 4,
                        child: SingleChildScrollView(child: _RightColumn(alerts: digest.alerts, searchQuery: searchQuery)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/* 中大屏右侧的规则、通知和告警列。 */
class _RightColumn extends StatelessWidget {
  const _RightColumn({required this.alerts, required this.searchQuery});

  final List<AlertEntity> alerts;
  final String searchQuery;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MonitorRulesCard(query: searchQuery),
        const SizedBox(height: AppSpacing.lg),
        const MonitorNotificationCard(),
        const SizedBox(height: AppSpacing.lg),
        MonitorRecentAlerts(alerts: alerts),
      ],
    );
  }
}

/* 监控数据加载骨架。 */
class _MonitorSkeleton extends StatelessWidget {
  const _MonitorSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xxxl),
      children: const [
        Row(
          children: [
            Expanded(child: Skeleton(height: 92)),
            SizedBox(width: AppSpacing.sm),
            Expanded(child: Skeleton(height: 92)),
            SizedBox(width: AppSpacing.sm),
            Expanded(child: Skeleton(height: 92)),
            SizedBox(width: AppSpacing.sm),
            Expanded(child: Skeleton(height: 92)),
          ],
        ),
        SizedBox(height: AppSpacing.lg),
        Skeleton(height: 360),
      ],
    );
  }
}
