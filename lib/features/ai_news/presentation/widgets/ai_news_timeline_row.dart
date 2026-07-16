import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/ai_news_item.dart';
import 'ai_news_article_card.dart';

/*
*单条资讯行:带背景的条目卡片 + 卡片间距。
*旧版的「左列时间 + 圆点 + 竖线」时间线槽已移除——它占约 15% 行宽,
*且与 meta 行的相对时间重复;日期分组仍由 [AiNewsDayHeader] 承担。
*保持原 API(item/onTap/eventSources)不变,调用方零改动。
*/
class AiNewsTimelineRow extends StatelessWidget {
  const AiNewsTimelineRow({
    required this.item,
    required this.onTap,
    this.eventSources = const [],
    super.key,
  });

  final AiNewsItem item;
  final VoidCallback onTap;
  final List<String> eventSources;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AiNewsArticleCard(item: item, onTap: onTap, eventSources: eventSources),
    );
  }
}
