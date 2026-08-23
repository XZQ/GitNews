import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/* 
*详情页顶部头(扁平、安静版)。
*工具风基线:不再用对角渐变 + 白字(那是"营销 Banner"观感),改为低饱和
*强调色薄底 + hairline 边框 + 一级文字,与全局冷静工具风一致。
*/
class GradientHeroHeader extends StatelessWidget {
  const GradientHeroHeader({required this.accent, required this.title, this.badges = const [], this.trailing, this.titleStyle, this.compact = false, super.key});

  final Color accent;
  final String title;
  final List<Widget> badges;
  final Widget? trailing;
  final TextStyle? titleStyle;

  // 在手机详情页使用更紧凑的内边距和标题尺度。
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isLight = colors.brightness == Brightness.light;
    final resolvedTitleStyle = titleStyle ?? (compact ? AppTypography.headlineMedium : AppTypography.headlineLarge);
    final trailingContent = trailing == null
        ? null
        : compact
        ? DefaultTextStyle.merge(maxLines: 3, overflow: TextOverflow.ellipsis, child: trailing!)
        : trailing;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        color: accent.withValues(alpha: isLight ? 0.08 : 0.16),
        border: Border.all(color: accent.withValues(alpha: isLight ? 0.22 : 0.34)),
      ),
      padding: EdgeInsets.all(compact ? AppSpacing.lg : AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (badges.isNotEmpty) ...[Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.xs, children: badges), SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg)],
          Text(
            title,
            maxLines: compact ? 3 : null,
            overflow: compact ? TextOverflow.ellipsis : null,
            style: resolvedTitleStyle.copyWith(color: colors.onSurface, height: 1.25),
          ),
          if (trailingContent != null) ...[SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg), trailingContent],
        ],
      ),
    );
  }
}

/* 
*头部用的中性胶囊标签。
*/
class HeroBadge extends StatelessWidget {
  const HeroBadge({required this.label, this.color, this.icon, super.key});

  final String label;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tinted = color ?? colors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs2),
      decoration: BoxDecoration(
        color: tinted.withValues(alpha: 0.1),
        border: Border.all(color: tinted.withValues(alpha: 0.26)),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 12, color: tinted), const SizedBox(width: AppSpacing.xs)],
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(color: tinted, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
