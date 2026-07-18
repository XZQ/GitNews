import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/domain/repo_entity.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/star_trend_chart.dart';
import '../domain/entities.dart';
import '../domain/monitor_repository.dart';
import 'monitor_recent_alerts.dart';

/*
*监控页的移动端设计稿布局。
*
*统计数字保持单行四宫格，仓库列表合并为一张分组卡片；桌面端继续使用原有高信息密度工作台。
*/
class MonitorMobileContent extends StatelessWidget {
  const MonitorMobileContent({required this.digest, super.key});

  final MonitorDigest digest;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
          sliver: SliverToBoxAdapter(child: _MonitorStatsRow(stats: digest.stats)),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xs),
          sliver: SliverToBoxAdapter(
            child: SectionHeader(title: l10n.tr('monitor.monitored_repos.title'), meta: l10n.tr('monitor.monitored_repos.subtitle')),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          sliver: SliverToBoxAdapter(child: _MonitoredRepoGroup(repos: digest.monitoredRepos)),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xl),
          sliver: SliverToBoxAdapter(child: MonitorRecentAlerts(alerts: digest.alerts)),
        ),
      ],
    );
  }
}

/* 移动端单行四项统计。 */
class _MonitorStatsRow extends StatelessWidget {
  const _MonitorStatsRow({required this.stats});

  final MonitorStats stats;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = <(String, String, Color)>[
      ('${stats.monitoredCount}', l10n.tr('monitor.status.monitored'), AppColors.brand),
      ('${stats.unreadAlertCount}', l10n.tr('monitor.status.unread'), AppColors.warning),
      ('${stats.triggeredTodayCount}', l10n.tr('monitor.status.triggered_today'), AppColors.info),
      ('${stats.totalAlertCount}', l10n.tr('monitor.status.total_alerts'), AppColors.success),
    ];
    return Row(
      children: [
        for (var index = 0; index < items.length; index++) ...[
          if (index != 0) const SizedBox(width: AppSpacing.sm),
          Expanded(child: _StatCell(value: items[index].$1, label: items[index].$2, color: items[index].$3)),
        ],
      ],
    );
  }
}

/* 单个监控统计单元。 */
class _StatCell extends StatelessWidget {
  const _StatCell({required this.value, required this.label, required this.color});

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;
    return AppCard(
      color: color.withValues(alpha: isLight ? 0.09 : 0.16),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.md),
      child: Column(
        children: [
          Text(value, style: AppTypography.monoDisplay.copyWith(color: value == '0' ? colors.onSurfaceVariant : color)),
          const SizedBox(height: AppSpacing.sm),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.bodySmall.copyWith(color: colors.onSurfaceVariant)),
        ],
      ),
    );
  }
}

/* 分组监控仓库卡片。 */
class _MonitoredRepoGroup extends StatelessWidget {
  const _MonitoredRepoGroup({required this.repos});

  final List<RepoEntity> repos;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var index = 0; index < repos.length; index++) ...[
            if (index != 0) Divider(height: 1, indent: AppSpacing.lg, endIndent: AppSpacing.lg, color: colors.outlineVariant),
            _MonitoredRepoRow(repo: repos[index]),
          ],
        ],
      ),
    );
  }
}

/* 分组卡片中的紧凑仓库行。 */
class _MonitoredRepoRow extends StatelessWidget {
  const _MonitoredRepoRow({required this.repo});

  final RepoEntity repo;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = Color(repo.accentArgb);
    final trend = repo.trend;
    return InkWell(
      onTap: () => context.go('/monitor/detail/${Uri.encodeComponent(repo.fullName)}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: AppSpacing.xxl,
              height: AppSpacing.xxl,
              decoration: BoxDecoration(color: accent.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(AppRadius.md)),
              alignment: Alignment.center,
              child: Text(_repoInitial(repo), style: AppTypography.titleSmall.copyWith(color: accent, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(repo.fullName, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.monoTitle.copyWith(color: colors.onSurface)),
                  const SizedBox(height: AppSpacing.xxs),
                  Row(
                    children: [
                      Container(width: AppSpacing.xs2, height: AppSpacing.xs2, decoration: BoxDecoration(color: accent, shape: BoxShape.circle)),
                      const SizedBox(width: AppSpacing.xs2),
                      Flexible(child: Text(repo.language, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.monoMeta.copyWith(color: colors.onSurfaceVariant))),
                      const SizedBox(width: AppSpacing.sm),
                      const Icon(Icons.star_rounded, size: 13, color: AppColors.starGold),
                      const SizedBox(width: AppSpacing.xxs),
                      Text(_shortNumber(repo.starCount), style: AppTypography.monoMeta.copyWith(color: AppColors.starGold)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            if (trend != null && trend.isNotEmpty) RepaintBoundary(child: Sparkline(values: trend, color: colors.primary, width: 64, height: 20)) else const SizedBox(width: 64, height: 20),
            const SizedBox(width: AppSpacing.sm),
            SizedBox(
              width: 48,
              child: Text(
                '${repo.starDelta > 0 ? '+' : ''}${_shortNumber(repo.starDelta)}',
                textAlign: TextAlign.right,
                style: AppTypography.monoMetric.copyWith(color: repo.starDelta >= 0 ? AppColors.trendUp : AppColors.trendDown),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* 从仓库名称生成设计稿中的单字母头像。 */
String _repoInitial(RepoEntity repo) {
  final name = repo.fullName.split('/').last;
  return name.isEmpty ? '?' : name.characters.first.toUpperCase();
}

/* 把仓库指标压缩为移动端短数字。 */
String _shortNumber(int value) {
  final absolute = value.abs();
  final sign = value < 0 ? '-' : '';
  if (absolute >= 1000000) {
    return '$sign${(absolute / 1000000).toStringAsFixed(1)}M';
  }
  if (absolute >= 1000) {
    return '$sign${(absolute / 1000).toStringAsFixed(1)}k';
  }
  return '$value';
}
