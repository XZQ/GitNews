import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../ai_news/application/ai_news_providers.dart';
import '../../../ai_news/domain/ai_news_item.dart';
import '../../../ai_news/presentation/widgets/ai_news_hero_banner.dart'
    show aiNewsCategoryColor, aiNewsCategoryLabel;
import '../../../../core/theme/app_colors.dart';
import 'home_section_preview_card.dart';

/// 首页 AI 动态 Top N 预览。
class HomeAiNewsPreview extends ConsumerWidget {
  const HomeAiNewsPreview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(aiNewsDigestProvider).items.take(4).toList();
    return HomeSectionPreviewCard<AiNewsItem>(
      title: 'AI 动态',
      subtitle: '每日 5 分钟读完 AI 世界',
      accentColor: AppColors.brand,
      icon: Icons.auto_awesome_rounded,
      path: '/ai_news',
      items: items,
      tileBuilder: (context, item, index) => PreviewRow(
        rank: '${index + 1}',
        rankColor: aiNewsCategoryColor(item.category),
        title: item.title,
        subtitle: '${item.source} · ${aiNewsCategoryLabel(item.category)}',
        meta: '+${item.likes}',
        onTap: () => context.go('/home/ai_news_detail/${item.id}'),
      ),
    );
  }
}
