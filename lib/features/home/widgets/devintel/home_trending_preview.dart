import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/demo_data.dart';
import '../../../../core/theme/app_colors.dart';
import 'home_section_preview_card.dart';

/// 首页 GitHub热榜 Top N 预览。
class HomeTrendingPreview extends StatelessWidget {
  const HomeTrendingPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final items = DemoData.trending.take(4).toList();
    return HomeSectionPreviewCard<DemoRepo>(
      title: 'GitHub热榜',
      subtitle: '今日 Star 增速榜',
      accentColor: AppColors.warning,
      icon: Icons.local_fire_department_rounded,
      path: '/trending',
      items: items,
      tileBuilder: (_, item, index) => PreviewRow(
        rank: '${index + 1}',
        rankColor: Color(item.color),
        title: item.fullName,
        subtitle: item.description,
        meta: '+${item.starDelta}',
        onTap: () => context.go(
          '/home/detail/${Uri.encodeComponent(item.fullName)}',
        ),
      ),
    );
  }
}
