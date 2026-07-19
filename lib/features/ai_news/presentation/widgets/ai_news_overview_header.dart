import 'package:flutter/material.dart';

import 'ai_hot_daily_card.dart';

/*
*AI 时间线的顶部情报区。
*只保留无需 Key 的 AI HOT 官方日报;当前热点已移动到总览首页。
*/
class AiNewsOverviewHeader extends StatelessWidget {
  const AiNewsOverviewHeader({super.key});

  @override
  /* 构建无需额外配置的官方日报区块。 */
  Widget build(BuildContext context) {
    return const AiHotDailyCard();
  }
}
