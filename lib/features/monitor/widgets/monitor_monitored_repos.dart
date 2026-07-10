import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/demo_data.dart';
import '../../../core/domain/repo_entity.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/data_provenance_badge.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/star_trend_chart.dart';

class MonitorMonitoredRepos extends StatelessWidget {
  const MonitorMonitoredRepos({required this.repos, super.key});

  final List<RepoEntity> repos;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppCard(
      padding: EdgeInsets.zero,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xs,
              ),
              child: SectionHeader(
                title: l10n.tr('monitor.monitored_repos.title'),
                subtitle: l10n.tr('monitor.monitored_repos.subtitle'),
              ),
            ),
          ),
          if (repos.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyView(
                icon: Icons.search_off_rounded,
                message: l10n.tr('monitor.monitored_repos.empty'),
              ),
            )
          else
            SliverList.builder(
              itemCount: repos.length,
              itemBuilder: (context, i) {
                return Column(
                  children: [
                    if (i != 0) const Divider(height: 1),
                    MonitorMonitoredRow(repo: repos[i]),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class MonitorMonitoredRow extends StatelessWidget {
  const MonitorMonitoredRow({required this.repo, super.key});

  final RepoEntity repo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final trend = repo.trend ?? DemoData.generateStarTrend(repo.starCount - 5000, 5000);
    return InkWell(
      onTap: () => context.go('/monitor/detail/${Uri.encodeComponent(repo.fullName)}'),
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
                color: Color(repo.accentArgb).withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              alignment: Alignment.center,
              child: Text(
                repo.language.isNotEmpty ? repo.language[0] : '?',
                style: AppTypography.labelMedium.copyWith(
                  color: Color(repo.accentArgb),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(repo.fullName, style: AppTypography.titleSmall),
                  Text(
                    repo.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelSmall.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  MetricBasisBadge(basis: repo.trendBasis),
                ],
              ),
            ),
            Sparkline(
              values: trend,
              color: AppColors.success,
              width: 90,
              height: 32,
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs2,
                vertical: AppSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                l10n.tr('monitor.monitored_repos.status_ok'),
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
