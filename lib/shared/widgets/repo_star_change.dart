import 'package:flutter/material.dart';

import '../../core/domain/observed_repo_growth.dart';
import '../../core/domain/repo_entity.dart';
import '../../core/i18n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

String repoStarChangeText(RepoEntity repo) {
  final delta = ObservedRepoGrowth.fromRepos([repo], days: repo.starDeltaDays).netChange;
  if (delta == null) return '—';
  final absolute = delta.abs();
  final value = absolute >= 1000 ? '${(absolute / 1000).toStringAsFixed(1)}k' : '$absolute';
  return '${delta > 0
      ? '+'
      : delta < 0
      ? '-'
      : ''}$value';
}

class RepoStarChange extends StatelessWidget {
  const RepoStarChange({required this.repo, super.key});
  final RepoEntity repo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final growth = ObservedRepoGrowth.fromRepos([repo], days: repo.starDeltaDays);
    final delta = growth.netChange;
    final color = delta == null || delta == 0
        ? Theme.of(context).colorScheme.onSurfaceVariant
        : delta > 0
        ? AppColors.trendUp
        : AppColors.trendDown;
    return Tooltip(
      message: growth.isEmpty
          ? l10n.tr('growth.empty')
          : '${l10n.tr('growth.title')}\n${growth.dates.first.toIso8601String().substring(0, 10)} — ${growth.dates.last.toIso8601String().substring(0, 10)} UTC',
      child: Text(
        repoStarChangeText(repo),
        textAlign: TextAlign.right,
        style: AppTypography.monoMetric.copyWith(color: color),
      ),
    );
  }
}
