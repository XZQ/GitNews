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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isBounded = constraints.maxHeight.isFinite;
          final visible = languages.take(isBounded ? 8 : 6).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: l10n.tr('project.section.language.title'),
                subtitle: l10n.tr('project.section.language.subtitle'),
              ),
              const SizedBox(height: AppSpacing.md),
              if (isBounded)
                Expanded(child: _LanguageList(languages: visible))
              else
                _LanguageList(
                  languages: visible,
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                ),
            ],
          );
        },
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
        count: entry.value.count,
        delta: 0,
        accentArgb: entry.value.accentArgb,
      );
    }).toList(growable: false);
  }
}

class _LanguageList extends StatelessWidget {
  const _LanguageList({
    required this.languages,
    this.physics,
    this.shrinkWrap = false,
  });

  final List<_LanguageSlice> languages;
  final ScrollPhysics? physics;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.zero,
      physics: physics,
      shrinkWrap: shrinkWrap,
      itemCount: languages.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs2),
      itemBuilder: (context, index) {
        final l = languages[index];
        return Row(
          children: [
            SizedBox(
              width: 24,
              child: Text(
                '${index + 1}',
                style: AppTypography.labelSmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
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
              child: Text(
                l.name,
                style: AppTypography.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '${l.percent.toStringAsFixed(1)}% · ${l.count}',
              style: AppTypography.labelMedium,
            ),
            const SizedBox(width: AppSpacing.xs2),
            Text(
              '${l.delta >= 0 ? '+' : ''}${l.delta.toStringAsFixed(1)}',
              style: AppTypography.labelSmall.copyWith(
                color: l.delta >= 0 ? AppColors.success : AppColors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      },
    );
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
    required this.count,
    required this.delta,
    required this.accentArgb,
  });

  final String name;
  final double percent;
  final int count;
  final double delta;
  final int accentArgb;
}
