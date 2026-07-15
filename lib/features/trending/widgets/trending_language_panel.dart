import 'package:flutter/material.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/section_header.dart';
import '../domain/entities.dart';

/* 
*语言分布面板:按分类(all/ai/web/system)筛选热门语言并展示占比。
*/
class TrendingLanguagePanel extends StatelessWidget {
  const TrendingLanguagePanel({super.key, required this.value, required this.onChanged, required this.languages});

  final String value;
  final ValueChanged<String> onChanged;
  final List<LanguageEntity> languages;

  static const _categoryMap = <String, List<String>>{
    'ai': ['Python', 'TypeScript', 'Rust'],
    'web': ['TypeScript', 'Java', 'Kotlin', 'Swift'],
    'system': ['Rust', 'C++', 'Go']
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final filtered = _filterLanguages(value, languages);
    final subtitle = _subtitleFor(l10n, value, filtered.length);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: l10n.tr('trending.languages'), subtitle: subtitle),
          const SizedBox(height: AppSpacing.md),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'all', label: Text(l10n.tr('common.all'))),
              const ButtonSegment(value: 'ai', label: Text('AI')),
              const ButtonSegment(value: 'web', label: Text('Web')),
              ButtonSegment(value: 'system', label: Text(l10n.tr('trending.language.segment.system')))
            ],
            selected: {value},
            onSelectionChanged: (s) => onChanged(s.first),
            showSelectedIcon: false,
          ),
          const SizedBox(height: AppSpacing.md),
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Text(l10n.tr('trending.language.empty'), style: AppTypography.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            )
          else
            for (final l in filtered) ...[_LangRow(name: l.name, percent: l.percent, delta: l.delta, color: Color(l.accentArgb)), const SizedBox(height: AppSpacing.md)]
        ],
      ),
    );
  }

  List<LanguageEntity> _filterLanguages(String category, List<LanguageEntity> languages) {
    if (category == 'all' || !_categoryMap.containsKey(category)) {
      return languages.take(7).toList();
    }
    final names = _categoryMap[category]!.toSet();
    return languages.where((l) => names.contains(l.name)).toList();
  }

  String _subtitleFor(AppLocalizations l10n, String category, int count) {
    switch (category) {
      case 'ai':
        return l10n.tr('trending.language.subtitle.ai').replaceAll('{count}', count.toString());
      case 'web':
        return l10n.tr('trending.language.subtitle.web').replaceAll('{count}', count.toString());
      case 'system':
        return l10n.tr('trending.language.subtitle.system').replaceAll('{count}', count.toString());
      case 'all':
      default:
        return l10n.tr('trending.language.subtitle.all').replaceAll('{count}', count.toString());
    }
  }
}

class _LangRow extends StatelessWidget {
  const _LangRow({required this.name, required this.percent, required this.delta, required this.color});

  final String name;
  final double percent;
  final double delta;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: AppSpacing.sm, height: AppSpacing.sm, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(AppRadius.dot))),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(name, style: AppTypography.titleSmall)),
        Text('${percent.toStringAsFixed(1)}%', style: AppTypography.labelMedium),
        const SizedBox(width: AppSpacing.sm),
        Text('${delta > 0 ? '+' : ''}${delta.toStringAsFixed(1)}%', style: AppTypography.labelSmall.copyWith(color: delta >= 0 ? AppColors.success : AppColors.danger, fontWeight: FontWeight.w600))
      ],
    );
  }
}
