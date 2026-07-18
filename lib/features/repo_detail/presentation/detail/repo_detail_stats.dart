import 'package:flutter/material.dart';

import '../../../../core/domain/repo_entity.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/adaptive_metric_grid.dart';
import '../../../../shared/widgets/app_card.dart';
import 'repo_detail_helpers.dart';

class RepoDetailStats extends StatelessWidget {
  const RepoDetailStats({required this.repo, required this.contributorCount, super.key});

  final RepoEntity repo;
  final int contributorCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AdaptiveMetricGrid(
      children: [
        _StatCard(
          label: l10n.tr('repo_detail.metric.total_stars'),
          value: shortNumber(repo.starCount),
          icon: Icons.star_rounded,
          color: AppColors.starGold,
        ),
        _StatCard(
          label: l10n.tr('repo_detail.metric.today_stars'),
          value: '+${shortNumber(repo.starDelta)}',
          icon: Icons.trending_up_rounded,
          color: AppColors.success,
        ),
        _StatCard(
          label: 'Fork',
          value: shortNumber(repo.forkCount),
          icon: Icons.call_split_rounded,
          color: AppColors.info,
        ),
        _StatCard(
          label: l10n.tr('repo_detail.metric.contributors'),
          value: '$contributorCount',
          icon: Icons.people_outline,
          color: Theme.of(context).colorScheme.primary,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      label: '$label $value',
      child: ExcludeSemantics(
        child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(height: AppSpacing.xs2),
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
              const SizedBox(height: AppSpacing.xxs),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelSmall.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
