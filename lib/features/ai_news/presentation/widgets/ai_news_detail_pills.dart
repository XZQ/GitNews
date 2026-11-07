import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/ai_news_item.dart';

/*
*资讯分类胶囊。
*/
class AiNewsDetailCategoryPill extends StatelessWidget {
  const AiNewsDetailCategoryPill({required this.category, super.key});

  // 当前资讯分类。
  final AiNewsCategory category;

  @override
  /* 构建设计稿中的琥珀色描边分类标签。 */
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm2, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.warning),
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Text(
        category.label,
        style: AppTypography.labelSmall.copyWith(color: AppColors.warning, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/*
*热度与精选状态的紧凑指标胶囊。
*/
class AiNewsDetailMetricPill extends StatelessWidget {
  const AiNewsDetailMetricPill({required this.icon, required this.label, this.positive = false, super.key});

  // 指标图标。
  final IconData icon;

  // 指标文案。
  final String label;

  // 是否使用成功语义色。
  final bool positive;

  @override
  /* 构建品牌色指标胶囊。 */
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = positive ? AppColors.success : AppColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs2),
      decoration: BoxDecoration(
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: accent),
          const SizedBox(width: AppSpacing.xs2),
          Flexible(
            child: Text(
              label,
              style: AppTypography.labelMedium.copyWith(color: accent, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
