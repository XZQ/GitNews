import 'package:flutter/material.dart';

import 'ai_hot_daily_card.dart';
import 'ai_hot_topics_card.dart';
import 'ai_news_digest_card.dart';

/*
*AI 时间线的顶部情报区。
*顺序固定为无 Key 官方日报 → 当前热点 → 可选“我的日报”。
*/
class AiNewsOverviewHeader extends StatelessWidget {
  const AiNewsOverviewHeader({super.key});

  @override
  /* 构建三个互不阻断的顶部区块。 */
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AiHotDailyCard(),
        AiHotTopicsCard(),
        AiNewsDigestCard(),
      ],
    );
  }
}
