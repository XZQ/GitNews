import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';

/// 设置页面桌面端 master-detail 区段。
enum ProfileSection {
  pro('升级 PRO', Icons.workspace_premium_outlined),
  collect('收藏的主题', Icons.bookmark_outline),
  developers('关注的开发者', Icons.people_outline),
  monitorTopics('监控的主题', Icons.visibility_outlined),
  monitorRules('监控规则', Icons.bolt_rounded),
  data('数据与缓存', Icons.storage_outlined),
  settings('偏好设置', Icons.tune),
  about('关于', Icons.info_outline);

  const ProfileSection(this.label, this.icon);

  final String label;
  final IconData icon;

  /// 区段强调色:跟随当前主题色(主区段)或保留语义色(子区段)。
  Color accentOf(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return switch (this) {
      ProfileSection.pro ||
      ProfileSection.monitorTopics ||
      ProfileSection.settings =>
        colors.primary,
      ProfileSection.collect || ProfileSection.data => AppColors.info,
      ProfileSection.developers => AppColors.success,
      ProfileSection.monitorRules => AppColors.warning,
      ProfileSection.about => colors.onSurfaceVariant,
    };
  }
}

/// 当前选中的桌面区段。NotFound → 默认 settings。
final selectedProfileSectionProvider =
    StateProvider<ProfileSection>((ref) => ProfileSection.settings);
