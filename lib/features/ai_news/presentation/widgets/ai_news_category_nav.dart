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
      height: isCompact ? 42 : 52,
      decoration: BoxDecoration(
        color: isCompact ? Theme.of(context).scaffoldBackgroundColor : theme.colorScheme.surface,
        border: isCompact ? null : Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant, width: 1)),
      ),
      padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xs, isCompact ? AppSpacing.lg : AppSpacing.lg, AppSpacing.xs),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _NavChip(
              label: l10n.tr('ai_news.category.all'),
              icon: Icons.dashboard_rounded,
              isSelected: selected == null,
              color: theme.colorScheme.onSurfaceVariant,
              compact: isCompact,
              onTap: () => onSelected(null),
            ),
            for (final c in AiNewsCategory.values) ...[
              const SizedBox(width: AppSpacing.sm),
              _NavChip(
                label: c.label,
                icon: aiNewsCategoryIcon(c),
                isSelected: selected == c,
                color: aiNewsCategoryColor(c),
                compact: isCompact,
                onTap: () => onSelected(c),
              )
            ]
          ],
        ),
      ),
    );
  }
}

class _NavChip extends StatelessWidget {
  const _NavChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.compact,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final Color color;

  // 是否使用设计稿中的移动端大号胶囊。
  final bool compact;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = compact ? theme.colorScheme.primary : color;
    final bg = compact ? (isSelected ? accent : theme.colorScheme.surface) : (isSelected ? accent.withValues(alpha: 0.14) : Colors.transparent);
    final fg = compact ? (isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant) : (isSelected ? accent : theme.colorScheme.onSurfaceVariant);
    final radius = BorderRadius.circular(compact ? AppRadius.sm : AppRadius.pill);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          height: compact ? 30 : null,
          padding: EdgeInsets.symmetric(horizontal: compact ? AppSpacing.md2 : AppSpacing.md, vertical: compact ? AppSpacing.xs : AppSpacing.xs2),
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: compact && isSelected ? accent : (isSelected ? accent.withValues(alpha: 0.38) : theme.colorScheme.outlineVariant)),
            borderRadius: radius,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!compact) ...[
                Icon(icon, size: 14, color: fg),
                const SizedBox(width: AppSpacing.xs2),
              ],
              Text(label, style: AppTypography.labelMedium.copyWith(color: fg, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600))
            ],
          ),
        ),
      ),
    );
  }
}
