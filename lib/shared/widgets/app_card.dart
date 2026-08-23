import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';

/* 
*通用容器卡片:纸面白 + hairline 外边框 + 圆角 + padding。
*工具风基线:不叠浮影,层级完全交给边框与背景明度差表达。
*/
class AppCard extends StatelessWidget {
  const AppCard({required this.child, this.padding = const EdgeInsets.all(AppSpacing.lg), this.onTap, this.color, super.key});

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;
    final radius = BorderRadius.circular(AppRadius.card);
    return Material(
      color: color ?? theme.cardTheme.color ?? colors.surface,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: colors.outlineVariant.withValues(alpha: isLight ? 0.72 : 1), width: 1),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
