import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/ai_news_item.dart';

/* 
*分类 → 主题色映射(用于 6px 分类圆点 / 徽章 / 时间线圆点)。
*5 个分类色相均匀分布在色环上,保证视觉可区分:
*模型=青、产品=蓝、论文=绿、技巧=橙、行业=品红。
*注意:分类色只出现在圆点级的小面积元素上,不做整片染色。
*/
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
