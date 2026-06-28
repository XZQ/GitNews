import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/ai_news_item.dart';

/// AI 动态分类筛选条。Chips + 时间窗下拉。
class AiNewsCategoryChips extends StatelessWidget {
  const AiNewsCategoryChips({
    required this.selected,
    required this.onSelected,
    required this.window,
    required this.onWindowChanged,
    super.key,
  });

  final AiNewsCategory? selected;
  final ValueChanged<AiNewsCategory?> onSelected;
  final String window;
  final ValueChanged<String> onWindowChanged;

  static const _windows = <String, String>{
    '24h': '24 小时',
    '7d': '7 天',
    '30d': '30 天',
    'all': '全部',
  };

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: 15,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          bottom: BorderSide(color: colors.outlineVariant, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(child: _buildChips(context)),
          PopupMenuButton<String>(
            tooltip: '时间窗',
            onSelected: onWindowChanged,
            itemBuilder: (_) => [
              for (final entry in _windows.entries)
                PopupMenuItem(
                  value: entry.key,
                  child: Row(
                    children: [
                      Icon(
                        window == entry.key
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: 16,
                        color: window == entry.key
                            ? colors.primary
                            : colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(entry.value),
                    ],
                  ),
                ),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 14,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    _windows[window]!,
                    style: AppTypography.labelMedium.copyWith(
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Icon(
                    Icons.arrow_drop_down_rounded,
                    size: 16,
                    color: colors.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChips(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: [
        _Chip(
          label: '全部',
          count: 10,
          selected: selected == null,
          onTap: () => onSelected(null),
        ),
        _Chip(
          label: '行业动态',
          count: 3,
          selected: selected == AiNewsCategory.industry,
          onTap: () => onSelected(AiNewsCategory.industry),
        ),
        _Chip(
          label: '技术突破',
          count: 4,
          selected: selected == AiNewsCategory.breakthrough,
          onTap: () => onSelected(AiNewsCategory.breakthrough),
        ),
        _Chip(
          label: '产业应用',
          count: 2,
          selected: selected == AiNewsCategory.application,
          onTap: () => onSelected(AiNewsCategory.application),
        ),
        _Chip(
          label: '投融资',
          count: 2,
          selected: selected == AiNewsCategory.funding,
          onTap: () => onSelected(AiNewsCategory.funding),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bg = selected
        ? colors.primary.withValues(alpha: 0.14)
        : colors.surfaceContainerHighest;
    final fg = selected ? colors.primary : colors.onSurfaceVariant;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(
              color: selected
                  ? colors.primary.withValues(alpha: 0.5)
                  : Colors.transparent,
            ),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: selected ? colors.primary : colors.onSurface,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: fg.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  '$count',
                  style: AppTypography.labelSmall.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
