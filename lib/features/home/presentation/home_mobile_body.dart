import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../widgets/home_mobile_radar_overview.dart';
import '../widgets/home_mobile_trending_overview.dart';

/*
* Home compact (<600) 分支：按设计稿的总览版面自上而下排布。
*
* 顺序为热门仓库 → Star 增长榜 → AI 雷达标签 → Agent 榜观察 → 话题趋势
*   → 本周信号热度 → 语言占比，页面到语言占比为止。原先挂在最底部的五条
*   雷达主题卡片不在设计稿内，已移除；进入完整雷达页的入口保留在 AI 雷达
*   区块标题上。
*/
class HomeMobileBody extends StatelessWidget {
  const HomeMobileBody({super.key});

  /* 构建只在移动端出现的八块总览内容。 */
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      children: const [
        HomeMobileAgentOverview(),
        SizedBox(height: AppSpacing.lg),
        HomeMobileTrendingOverview(),
        SizedBox(height: AppSpacing.lg),
        HomeMobileRadarOverview(),
      ],
    );
  }
}
