import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../widgets/home_mobile_radar_overview.dart';
import '../widgets/home_mobile_trending_overview.dart';

/*
* Home compact (<600) 分支：GitHub 热榜三块 + AI 雷达五块。
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
        HomeMobileTrendingOverview(),
        SizedBox(height: AppSpacing.lg),
        HomeMobileRadarOverview(),
        SizedBox(height: AppSpacing.lg),
        HomeMobileRadarTopicList(),
      ],
    );
  }
}
