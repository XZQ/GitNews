import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../application/ai_news_enrichment_providers.dart';
import '../../domain/ai_news_item.dart';
import 'ai_news_detail_components.dart';
import 'ai_news_detail_extended.dart';
import 'ai_news_detail_insights.dart';
import 'ai_news_detail_overview.dart';

/*
*AI 资讯详情的单页纵向阅读流。
*
*概览、AI 解读与延伸内容共享一个滚动位置,不使用横向分页。
*/
class AiNewsDetailContent extends ConsumerWidget {
  const AiNewsDetailContent({
    required this.item,
    this.relatedItems = const [],
    this.showEnrichment = true,
    this.onOpenOriginal,
    this.onOpenRelated,
    this.onViewMore,
    super.key,
  });

  // 当前资讯。
  final AiNewsItem item;

  // 本地相关推荐。
  final List<AiNewsItem> relatedItems;

  // 是否读取本地 AI 增强状态。
  final bool showEnrichment;

  // 打开原文操作。
  final VoidCallback? onOpenOriginal;

  // 打开相关推荐操作。
  final ValueChanged<AiNewsItem>? onOpenRelated;

  // 返回资讯列表操作。
  final VoidCallback? onViewMore;

  @override
  /* 构建一个可上下滚动的完整详情页。 */
  Widget build(BuildContext context, WidgetRef ref) {
    final enrichment = showEnrichment ? ref.watch(aiNewsEnrichmentProvider(item.id)).valueOrNull : null;
    return AiNewsDetailPageFrame(
      scrollKey: const PageStorageKey('ai-news-detail-scroll'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AiNewsDetailOverview(
            item: item,
            enrichment: enrichment,
            onOpenOriginal: onOpenOriginal,
          ),
          const SizedBox(height: AppSpacing.xl),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.xl),
          AiNewsDetailInsights(
            item: item,
            showEnrichment: showEnrichment,
          ),
          const SizedBox(height: AppSpacing.xl),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.xl),
          AiNewsDetailExtended(
            item: item,
            relatedItems: relatedItems,
            onOpenOriginal: onOpenOriginal,
            onOpenRelated: onOpenRelated,
            onViewMore: onViewMore,
          ),
        ],
      ),
    );
  }
}
