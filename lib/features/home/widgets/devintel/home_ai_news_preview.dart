import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/data_provenance_badge.dart';
import '../../../../shared/widgets/home_section_preview_card.dart';
import '../../../ai_news/application/ai_news_providers.dart';
import '../../../ai_news/domain/ai_news_item.dart';
import '../../../ai_news/presentation/widgets/ai_news_category_style.dart';

/* 
*首页 AI 动态 Top N 预览。
*数据来自 [aiNewsItemsNotifierProvider](远端 aihot.virxact.com);加载中显示空列表占位。
*/
class HomeAiNewsPreview extends ConsumerWidget {
  const HomeAiNewsPreview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(aiNewsItemsNotifierProvider);
    final freshness = ref.watch(aiNewsFreshnessProvider);
    final items = async.value?.take(4).toList() ?? const <AiNewsItem>[];
    return HomeSectionPreviewCard<AiNewsItem>(
      title: l10n.tr('home.section.ai_news.title'),
      subtitle: l10n.tr('home.section.ai_news.subtitle'),
      accentColor: AppColors.brand,
      icon: Icons.auto_awesome_rounded,
      path: '/ai_news',
      trailing: DataFreshnessBadge(freshness: freshness),
      items: items,
      tileBuilder: (context, item, index) => PreviewRow(
        rank: '${index + 1}',
        rankColor: aiNewsCategoryColor(item.category),
        title: item.title,
        subtitle: '${item.source} · ${item.category.label}',
        meta: '${item.score}',
        onTap: () => context.go('/ai_news'),
      ),
    );
  }
}
