import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/repo_entity.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/data_provenance_badge.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/gradient_hero_header.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../../shared/widgets/secondary_page_scaffold.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/star_trend_chart.dart';
import '../application/monitor_providers.dart';
import '../domain/entities.dart';
import '../widgets/monitor_alert_list_tile.dart';

/*
*监控详情。
*
*移动端使用单列阅读，桌面端把趋势和告警并排；两端只共享数据卡，
*不再把同一棵页面结构直接缩放。
*/
class MonitorDetailPage extends ConsumerWidget {
  const MonitorDetailPage({required this.repoFullName, super.key});

  // `owner/name` 形式的目标仓库。
  final String repoFullName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(visibleMonitorDigestProvider);
    return SecondaryPageScaffold(
      title: l10n.tr('monitor.detail_title'),
      subtitle: repoFullName,
      icon: Icons.notifications_active_rounded,
      fallbackPath: '/monitor',
      body: state.when(
        data: (digest) {
          if (digest.monitoredRepos.isEmpty) {
            return EmptyView(
              icon: Icons.visibility_off_outlined,
              message: l10n.tr('monitor.empty'),
            );
          }
          final repo = digest.repoByFullName(repoFullName);
          if (repo == null) {
            return EmptyView(
              icon: Icons.visibility_off_outlined,
              message: l10n.tr('monitor.empty.not_in_list'),
            );
          }
          final repoAlerts = digest.alerts.where((alert) => alert.repoFullName == repo.fullName).take(5).toList(growable: false);
          return ResponsiveLayout(
            compact: (_) => _Mobile(repo: repo, alerts: repoAlerts),
            medium: (_) => CenteredContent(
              maxWidth: 900,
              padding: EdgeInsets.zero,
              child: _Mobile(repo: repo, alerts: repoAlerts),
            ),
            expanded: (_) => CenteredContent(
              child: _Desktop(repo: repo, alerts: repoAlerts),
            ),
          );
        },
        loading: () => const _DetailSkeleton(),
        error: (error, stack) => ErrorView(
          error: error.asAppException(stack),
          onRetry: () => forceRefreshMonitor(ref),
        ),
      ),
    );
  }
}

/*
*监控详情的移动端单列编排。
*/
class _Mobile extends StatelessWidget {
  const _Mobile({required this.repo, required this.alerts});

  // 当前仓库快照。
  final RepoEntity repo;

  // 当前仓库最近五条告警。
  final List<AlertEntity> alerts;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      children: [
        _MonitorHero(repo: repo, compact: true),
        const SizedBox(height: AppSpacing.lg),
        _TrendCard(repo: repo),
        const SizedBox(height: AppSpacing.lg),
        _AlertHistoryCard(alerts: alerts),
      ],
    );
  }
}

/*
*监控详情的桌面端宽屏编排。
*/
class _Desktop extends StatelessWidget {
  const _Desktop({required this.repo, required this.alerts});

  // 当前仓库快照。
  final RepoEntity repo;

  // 当前仓库最近五条告警。
  final List<AlertEntity> alerts;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      children: [
        _MonitorHero(repo: repo),
        const SizedBox(height: AppSpacing.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 8, child: _TrendCard(repo: repo)),
            const SizedBox(width: AppSpacing.lg),
            Expanded(flex: 4, child: _AlertHistoryCard(alerts: alerts)),
          ],
        ),
      ],
    );
  }
}

/*
*监控仓库标题和数据口径。
*/
class _MonitorHero extends StatelessWidget {
  const _MonitorHero({required this.repo, this.compact = false});

  // 当前仓库快照。
  final RepoEntity repo;

  // 是否使用移动端紧凑标题。
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return GradientHeroHeader(
      accent: Color(repo.accentArgb),
      title: repo.fullName,
      compact: compact,
      badges: [
        HeroBadge(label: repo.language, icon: Icons.bolt_rounded),
        HeroBadge(label: '★ ${_shortNumber(repo.starCount)}', icon: Icons.star_rounded),
        HeroBadge(label: '⑂ ${_shortNumber(repo.forkCount)}', icon: Icons.call_split_rounded),
        MetricBasisBadge(
          basis: repo.trendBasis,
          compact: compact,
          inverse: true,
        ),
      ],
      trailing: Text(
        repo.description,
        style: AppTypography.bodyMedium.copyWith(color: Colors.white.withValues(alpha: 0.92)),
      ),
    );
  }
}

/*
*只展示仓库提供的 Star 趋势；没有数据时显示明确空状态。
*/
class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.repo});

  // 当前仓库快照。
  final RepoEntity repo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final trend = repo.trend;
    final hasTrend = trend != null && trend.isNotEmpty;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: l10n.tr('monitor.section.realtime_trend'),
            subtitle: '${l10n.tr('monitor.section.realtime_trend.subtitle')} · ${l10n.tr(repo.trendBasis.labelKey)}',
          ),
          const SizedBox(height: AppSpacing.md),
          if (hasTrend)
            StarTrendChart(
              series: [
                ChartSeries(
                  values: trend,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
              height: 220,
            )
          else
            SizedBox(
              height: 180,
              child: EmptyView(
                icon: Icons.show_chart_rounded,
                message: l10n.tr('monitor.section.realtime_trend.empty'),
              ),
            ),
        ],
      ),
    );
  }
}

/*
*当前仓库最近告警；没有命中时不再保留空白大卡。
*/
class _AlertHistoryCard extends StatelessWidget {
  const _AlertHistoryCard({required this.alerts});

  // 当前仓库最近五条告警。
  final List<AlertEntity> alerts;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: l10n.tr('monitor.section.alert_history'),
            subtitle: l10n.tr('monitor.section.alert_history.subtitle'),
          ),
          const SizedBox(height: AppSpacing.md),
          if (alerts.isEmpty)
            EmptyView(
              icon: Icons.notifications_none_rounded,
              message: l10n.tr('monitor.section.alert_history.empty'),
            )
          else
            for (var index = 0; index < alerts.length; index++) ...[
              if (index != 0) const Divider(height: AppSpacing.lg),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.history_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(alerts[index].repoFullName, style: AppTypography.titleSmall),
                subtitle: Text('${monitorAlertMetricLabel(context, alerts[index])} · ${alerts[index].time}'),
                trailing: Text(
                  alerts[index].value,
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
        ],
      ),
    );
  }
}

/*
*监控详情加载骨架。
*/
class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

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
        Skeleton(height: 180),
        SizedBox(height: AppSpacing.lg),
        Skeleton(height: 300),
        SizedBox(height: AppSpacing.lg),
        Skeleton(height: 220),
      ],
    );
  }
}

/* 把整数压缩为详情头适用的短格式。 */
String _shortNumber(int value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}M';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}k';
  }
  return '$value';
}
