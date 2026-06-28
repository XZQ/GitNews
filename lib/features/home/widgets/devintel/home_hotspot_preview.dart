import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../tech_hotspot/data/mock_tech_hotspot.dart';
import '../../../tech_hotspot/domain/tech_hotspot_models.dart';
import 'home_section_preview_card.dart';

/// 首页技术趋势 Top N 预览。
class HomeHotspotPreview extends StatelessWidget {
  const HomeHotspotPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final items = MockTechHotspot.topics.take(4).toList();
    return HomeSectionPreviewCard<TechTopic>(
      title: '技术趋势',
      subtitle: '主题、语言与栈脉搏',
      accentColor: AppColors.danger,
      icon: Icons.whatshot_rounded,
      path: '/tech_hotspot',
      items: items,
      tileBuilder: (_, item, index) => PreviewRow(
        rank: '${index + 1}',
        rankColor: _heatColor(item.heat),
        title: item.name,
        subtitle: '${item.category} · ${item.relatedRepos} 仓库',
        meta: '+${item.growth.toStringAsFixed(1)}%',
        onTap: () {},
      ),
    );
  }

  static Color _heatColor(int heat) {
    if (heat >= 90) return AppColors.danger;
    if (heat >= 75) return AppColors.warning;
    return AppColors.info;
  }
}
