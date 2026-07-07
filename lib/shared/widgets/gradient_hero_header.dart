import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/* 
*渐变英雄头:用于详情页顶部。
*通过 [accent] 控制主色调,组件自动生成 brand↔accent↔black 的对角渐变,
*保证所有二级/三级详情页视觉统一。
*/
class GradientHeroHeader extends StatelessWidget {
  const GradientHeroHeader({
    required this.accent,
    required this.title,
    this.badges = const [],
    this.trailing,
    this.titleStyle,
    super.key,
  });

  final Color accent;
  final String title;
  final List<Widget> badges;
  final Widget? trailing;
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(accent, AppColors.brand, 0.18)!,
            Color.lerp(accent, Colors.black, 0.46)!,
          ],
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (badges.isNotEmpty) ...[
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: badges,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          Text(
            title,
            style: (titleStyle ?? AppTypography.headlineLarge).copyWith(
              color: Colors.white,
              height: 1.25,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(height: AppSpacing.lg),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/* 
*渐变头部使用的半透明胶囊标签。
*/
class HeroBadge extends StatelessWidget {
  const HeroBadge({
    required this.label,
    this.color,
    this.icon,
    super.key,
  });

  final String label;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final tinted = color ?? Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs2,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: tinted),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
