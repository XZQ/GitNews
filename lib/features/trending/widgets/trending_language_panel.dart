import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/section_header.dart';
import '../domain/entities.dart';

/// 语言分布面板:按分类(all/ai/web/system)筛选热门语言并展示占比。
class TrendingLanguagePanel extends StatelessWidget {
  const TrendingLanguagePanel({
    super.key,
    required this.value,
    required this.onChanged,
    required this.languages,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final List<LanguageEntity> languages;

  static const _categoryMap = <String, List<String>>{
    'ai': ['Python', 'TypeScript', 'Rust'],
    'web': ['TypeScript', 'Java', 'Kotlin', 'Swift'],
    'system': ['Rust', 'C++', 'Go'],
  };

  @override
  Widget build(BuildContext context) {
    final filtered = _filterLanguages(value, languages);
    final subtitle = _subtitleFor(value, filtered.length);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: '语言分布',
            subtitle: subtitle,
          ),
          const SizedBox(height: AppSpacing.md),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'all', label: Text('全部')),
              ButtonSegment(value: 'ai', label: Text('AI')),
              ButtonSegment(value: 'web', label: Text('Web')),
              ButtonSegment(value: 'system', label: Text('系统')),
            ],
            selected: {value},
            onSelectionChanged: (s) => onChanged(s.first),
            showSelectedIcon: false,
          ),
          const SizedBox(height: AppSpacing.md),
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Text(
                '该分类暂无数据',
                style: AppTypography.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            for (final l in filtered) ...[
              _LangRow(
                name: l.name,
                percent: l.percent,
                delta: l.delta,
                color: Color(l.accentArgb),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
        ],
      ),
    );
  }

  List<LanguageEntity> _filterLanguages(
    String category,
    List<LanguageEntity> languages,
  ) {
    if (category == 'all' || !_categoryMap.containsKey(category)) {
      return languages.take(7).toList();
    }
    final names = _categoryMap[category]!.toSet();
    return languages.where((l) => names.contains(l.name)).toList();
  }

  String _subtitleFor(String category, int count) {
    switch (category) {
      case 'ai':
        return 'AI / ML 方向 · $count 种语言';
      case 'web':
        return 'Web 与前端 · $count 种语言';
      case 'system':
        return '系统与基础设施 · $count 种语言';
      case 'all':
      default:
        return '热门仓库的编程语言占比 · 共 $count 种';
    }
  }
}

class _LangRow extends StatelessWidget {
  const _LangRow({
    required this.name,
    required this.percent,
    required this.delta,
    required this.color,
  });

  final String name;
  final double percent;
  final double delta;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: AppSpacing.sm,
          height: AppSpacing.sm,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppRadius.dot),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            name,
            style: AppTypography.titleSmall,
          ),
        ),
        Text(
          '${percent.toStringAsFixed(1)}%',
          style: AppTypography.labelMedium,
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '${delta > 0 ? '+' : ''}${delta.toStringAsFixed(1)}%',
          style: AppTypography.labelSmall.copyWith(
            color: delta >= 0 ? AppColors.success : AppColors.danger,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
