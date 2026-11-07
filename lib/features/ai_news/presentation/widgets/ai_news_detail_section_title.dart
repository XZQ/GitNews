import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/*
*详情区块标题,统一图标、字号和间距。
*/
class AiNewsDetailSectionTitle extends StatelessWidget {
  const AiNewsDetailSectionTitle({required this.icon, required this.title, this.trailing, super.key});

  // 标题图标。
  final IconData icon;

  // 标题文案。
  final String title;

  // 可选尾部操作。
  final Widget? trailing;

  @override
  /* 构建详情区块标题行。 */
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 22, color: colors.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(title, style: AppTypography.titleLarge.copyWith(color: colors.onSurface)),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
