import 'package:flutter/material.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/breakpoint.dart';
import '../../domain/ai_news_item.dart';
import 'ai_news_category_style.dart';

/* 
*分类导航条(顶部 chips)。
*工具风基线:分类身份用 6px 颜色点表达,选中态用中性底 + 一级文字
*对比,不再整块染成分类色;移动端同样告别实心主色胶囊。
*/
class AiNewsCategoryNav extends StatelessWidget {
  const AiNewsCategoryNav({required this.selected, required this.onSelected, super.key});

  final AiNewsCategory? selected;
  final ValueChanged<AiNewsCategory?> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isCompact = Breakpoints.isCompact(context);
    return Container(
      height: isCompact ? 42 : 48,
      decoration: BoxDecoration(
        color: isCompact ? Theme.of(context).scaffoldBackgroundColor : theme.colorScheme.surface,
        border: isCompact ? null : Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _NavChip(label: l10n.tr('ai_news.category.all'), dotColor: null, isSelected: selected == null, compact: isCompact, onTap: () => onSelected(null)),
            for (final c in AiNewsCategory.values) ...[
              const SizedBox(width: AppSpacing.sm),
              _NavChip(label: c.label, dotColor: aiNewsCategoryColor(c), isSelected: selected == c, compact: isCompact, onTap: () => onSelected(c)),
            ],
          ],
        ),
      ),
    );
  }
}

class _NavChip extends StatelessWidget {
  const _NavChip({required this.label, required this.dotColor, required this.isSelected, required this.compact, required this.onTap});

  final String label;

  // 分类身份色,仅用于 6px 圆点;null 表示"全部"(无圆点)。
  final Color? dotColor;
  final bool isSelected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bg = isSelected ? colors.surfaceContainerHighest : Colors.transparent;
    final fg = isSelected ? colors.onSurface : colors.onSurfaceVariant;
    final radius = BorderRadius.circular(AppRadius.pill);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          height: compact ? 30 : null,
          padding: EdgeInsets.symmetric(horizontal: compact ? AppSpacing.md : AppSpacing.md, vertical: compact ? AppSpacing.xs : AppSpacing.xs2),
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: isSelected ? colors.outline : colors.outlineVariant),
            borderRadius: radius,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (dotColor != null) ...[
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: AppSpacing.xs2),
              ],
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(color: fg, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
