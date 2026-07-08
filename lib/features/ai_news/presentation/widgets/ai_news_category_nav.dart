import 'package:flutter/material.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/ai_news_item.dart';
import 'ai_news_category_style.dart';

/* 
*分类导航条(顶部 chips)。
*/
class AiNewsCategoryNav extends StatelessWidget {
  const AiNewsCategoryNav({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final AiNewsCategory? selected;
  final ValueChanged<AiNewsCategory?> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _NavChip(
              label: l10n.tr('ai_news.category.all'),
              icon: Icons.dashboard_rounded,
              isSelected: selected == null,
              color: theme.colorScheme.onSurfaceVariant,
              onTap: () => onSelected(null),
            ),
            for (final c in AiNewsCategory.values) ...[
              const SizedBox(width: AppSpacing.sm),
              _NavChip(
                label: c.label,
                icon: aiNewsCategoryIcon(c),
                isSelected: selected == c,
                color: aiNewsCategoryColor(c),
                onTap: () => onSelected(c),
              ),
            ],
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
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = isSelected ? color.withValues(alpha: 0.14) : Colors.transparent;
    final fg = isSelected ? color : theme.colorScheme.onSurfaceVariant;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs2,
          ),
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(
              color: isSelected
                  ? color.withValues(alpha: 0.45)
                  : theme.colorScheme.outlineVariant,
            ),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: fg),
              const SizedBox(width: AppSpacing.xs2),
              Text(label, style: AppTypography.labelMedium.copyWith(color: fg)),
            ],
          ),
        ),
      ),
    );
  }
}
