import 'package:flutter/material.dart';

import '../../../../core/domain/repo_entity.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/section_header.dart';

class ProjectLanguageDistribution extends StatelessWidget {
  const ProjectLanguageDistribution({required this.repos, super.key});

  final List<RepoEntity> repos;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languages = _languages(repos);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: l10n.tr('project.section.language.title'),
            subtitle: l10n.tr('project.section.language.subtitle'),
          ),
          const SizedBox(height: AppSpacing.md),
          Column(
            children: [
              for (final l in languages.take(6))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Color(l.accentArgb),
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(l.name, style: AppTypography.bodyMedium),
                      ),
                      Text(
                        '${l.percent.toStringAsFixed(1)}%',
                        style: AppTypography.labelMedium,
                      ),
                      const SizedBox(width: AppSpacing.xs2),
                      Text(
                        '${l.delta >= 0 ? '+' : ''}${l.delta.toStringAsFixed(1)}%',
                        style: AppTypography.labelSmall.copyWith(
                          color: l.delta >= 0
                              ? AppColors.success
                              : AppColors.danger,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  List<_LanguageSlice> _languages(List<RepoEntity> repos) {
    if (repos.isEmpty) return const [];
    final counts = <String, _LanguageCount>{};
    for (final repo in repos) {
      final current = counts[repo.language];
      counts[repo.language] = _LanguageCount(
        count: (current?.count ?? 0) + 1,
        accentArgb: repo.accentArgb,
      );
    }
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.count.compareTo(a.value.count));
    return entries.map((entry) {
      return _LanguageSlice(
        name: entry.key,
        percent: entry.value.count / repos.length * 100,
        delta: 0,
        accentArgb: entry.value.accentArgb,
      );
    }).toList(growable: false);
  }
}

class _LanguageCount {
  const _LanguageCount({required this.count, required this.accentArgb});

  final int count;
  final int accentArgb;
}

class _LanguageSlice {
  const _LanguageSlice({
    required this.name,
    required this.percent,
    required this.delta,
    required this.accentArgb,
  });

  final String name;
  final double percent;
  final double delta;
  final int accentArgb;
}
