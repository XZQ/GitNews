import 'package:flutter/material.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../domain/tech_hotspot_models.dart';

/* 
*编程语言分布与排行面板。
*/
class TechHotspotLanguagePanel extends StatelessWidget {
  const TechHotspotLanguagePanel({required this.languages, super.key});

  final List<LanguageStat> languages;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: LayoutBuilder(builder: (context, constraints) {
          final isBounded = constraints.maxHeight.isFinite;
          final visible = languages.take(8).toList(growable: false);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: isBounded ? MainAxisSize.max : MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.code_rounded, size: 16, color: AppColors.info),
                  const SizedBox(width: AppSpacing.sm),
                  Text(l10n.tr('tech_hotspot.language_share'), style: AppTypography.titleSmall.copyWith(color: colors.onSurface, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Text('Top ${visible.length}', style: AppTypography.labelSmall.copyWith(color: colors.onSurfaceVariant))
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              _LangBar(languages: visible),
              const SizedBox(height: AppSpacing.md),
              if (isBounded) Expanded(child: _LangList(languages: visible)) else _LangList(languages: visible, physics: const NeverScrollableScrollPhysics(), shrinkWrap: true)
            ],
          );
        }));
  }
}

class _LangBar extends StatelessWidget {
  const _LangBar({required this.languages});

  final List<LanguageStat> languages;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Row(children: [for (final s in languages) Expanded(flex: s.percent.round(), child: Container(height: 8, color: Color(s.color), margin: const EdgeInsets.only(right: 1)))]),
    );
  }
}

class _LangList extends StatelessWidget {
  const _LangList({required this.languages, this.physics, this.shrinkWrap = false});

  final List<LanguageStat> languages;
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
      itemBuilder: (context, index) => _LangRow(stat: languages[index], rank: index + 1),
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
          SizedBox(width: 18, child: Text('$rank', style: AppTypography.labelSmall.copyWith(color: colors.onSurfaceVariant))),
          const SizedBox(width: AppSpacing.sm),
          Container(width: AppSpacing.xs2, height: AppSpacing.xs2, decoration: BoxDecoration(color: Color(stat.color), borderRadius: BorderRadius.circular(AppRadius.dot))),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(stat.name, style: AppTypography.bodyMedium.copyWith(color: colors.onSurface, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: AppSpacing.sm),
          Text('${stat.percent.toStringAsFixed(1)}% · ${stat.repoCount}', style: AppTypography.labelSmall.copyWith(color: colors.onSurfaceVariant)),
          const SizedBox(width: AppSpacing.sm),
          Icon(isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, size: 12, color: isUp ? AppColors.trendUp : AppColors.trendDown),
          const SizedBox(width: AppSpacing.xxs),
          Text('${isUp ? '+' : ''}${stat.delta.toStringAsFixed(1)}', style: AppTypography.labelSmall.copyWith(color: isUp ? AppColors.trendUp : AppColors.trendDown, fontWeight: FontWeight.w700))
        ],
      ),
    );
  }
}
