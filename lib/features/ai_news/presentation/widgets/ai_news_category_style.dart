import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/ai_news_item.dart';

/* 分类 → 主题色映射(用于徽章 / 标签 chip / 时间线圆点)。 */
/*  */
/* 5 个分类色相均匀分布在色环上,保证视觉可区分: */
/* 模型=青、产品=蓝、论文=绿、技巧=橙、行业=品红。 */
Color aiNewsCategoryColor(AiNewsCategory c) {
  switch (c) {
    case AiNewsCategory.aiModels:
      return AppColors.brand;
    case AiNewsCategory.aiProducts:
      return AppColors.info;
    case AiNewsCategory.paper:
      return AppColors.success;
    case AiNewsCategory.tip:
      return AppColors.warning;
    case AiNewsCategory.industry:
      return AppColors.accentPink;
  }
}

/* 分类 → Material 图标(用于底部导航栏)。 */
IconData aiNewsCategoryIcon(AiNewsCategory c) {
  switch (c) {
    case AiNewsCategory.aiModels:
      return Icons.hub_rounded;
    case AiNewsCategory.aiProducts:
      return Icons.apps_rounded;
    case AiNewsCategory.paper:
      return Icons.menu_book_rounded;
    case AiNewsCategory.tip:
      return Icons.lightbulb_rounded;
    case AiNewsCategory.industry:
      return Icons.trending_up_rounded;
  }
}
