import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/gradient_hero_header.dart';
import '../../domain/ai_news_item.dart';
import '../widgets/ai_news_hero_banner.dart'
    show aiNewsCategoryColor, aiNewsCategoryLabel;

class AiNewsDetailCover extends StatelessWidget {
  const AiNewsDetailCover({required this.item, super.key});

  final AiNewsItem item;

  @override
  Widget build(BuildContext context) {
    final accent = Color(item.coverColor);
    return GradientHeroHeader(
      accent: accent,
      title: item.title,
      badges: [
        HeroBadge(
          label: aiNewsCategoryLabel(item.category),
          color: aiNewsCategoryColor(item.category),
        ),
        if (item.isHero)
          const HeroBadge(label: '头版', color: AppColors.starGold),
        if (item.isMock) const HeroBadge(label: '本地样例', color: AppColors.info),
      ],
    );
  }
}
