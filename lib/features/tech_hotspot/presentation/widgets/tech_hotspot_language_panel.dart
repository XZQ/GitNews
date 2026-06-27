import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/tech_hotspot_models.dart';

/// 编程语言分布与排行面板。
class TechHotspotLanguagePanel extends StatelessWidget {
  const TechHotspotLanguagePanel({required this.languages, super.key});

  final List<LanguageStat> languages;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.code_rounded, size: 16, color: AppColors.info),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '语言占比',
                style: AppTypography.titleSmall.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                'Top ${languages.length}',
                style: AppTypography.labelSmall.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _LangBar(languages: languages),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < languages.length; i++)
            _LangRow(
              stat: languages[i],
              rank: i + 1,
            ),
        ],
      ),
    );
  }
}

class _LangBar extends StatelessWidget {
  const _LangBar({required this.languages});

  final List<LanguageStat> languages;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Row(
        children: [
          for (final s in languages)
            Expanded(
              flex: s.percent.round(),
              child: Container(
                height: 8,
                color: Color(s.color),
                margin: const EdgeInsets.only(right: 1),
              ),
            ),
        ],
      ),
    );
  }
}

class _LangRow extends StatelessWidget {
  const _LangRow({required this.stat, required this.rank});

  final LanguageStat stat;
  final int rank;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isUp = stat.delta >= 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            child: Text(
              '$rank',
              style: AppTypography.labelSmall.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: Color(stat.color),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            stat.name,
            style: AppTypography.bodyMedium.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '${stat.percent.toStringAsFixed(1)}% · ${stat.repoCount}',
            style: AppTypography.labelSmall.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Icon(
            isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            size: 12,
            color: isUp ? AppColors.trendUp : AppColors.trendDown,
          ),
          const SizedBox(width: 2),
          Text(
            '${isUp ? '+' : ''}${stat.delta.toStringAsFixed(1)}',
            style: AppTypography.labelSmall.copyWith(
              color: isUp ? AppColors.trendUp : AppColors.trendDown,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
