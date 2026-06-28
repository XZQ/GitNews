import 'package:flutter/material.dart';

import '../../../ai_news/data/mock_ai_news.dart';
import '../../../ai_news/domain/ai_news_item.dart';
import '../../../ai_news/presentation/widgets/ai_news_hero_banner.dart'
    show aiNewsCategoryColor, aiNewsCategoryLabel;
import '../../../../core/theme/app_colors.dart';
import 'home_section_preview_card.dart';

/// 首页 AI 动态 Top N 预览。
class HomeAiNewsPreview extends StatelessWidget {
  const HomeAiNewsPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final items = MockAiNews.all.take(4).toList();
    return HomeSectionPreviewCard<AiNewsItem>(
      title: 'AI 动态',
      subtitle: '每日 5 分钟读完 AI 世界',
      accentColor: AppColors.brand,
      icon: Icons.auto_awesome_rounded,
      path: '/ai_news',
      items: items,
      tileBuilder: (_, item, index) => PreviewRow(
        rank: '${index + 1}',
        rankColor: aiNewsCategoryColor(item.category),
        title: item.title,
        subtitle: '${item.source} · ${aiNewsCategoryLabel(item.category)}',
        meta: '+${item.likes}',
        onTap: () {},
      ),
    );
  }
}
