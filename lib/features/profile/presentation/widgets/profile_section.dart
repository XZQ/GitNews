import 'package:flutter/material.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';

/* 
*设置页面桌面端 master-detail 区段。
*/
enum ProfileSection {
  collect('profile.section.collect', Icons.bookmark_outline),
  developers('profile.section.developers', Icons.people_outline),
  monitorTopics('profile.section.monitor_topics', Icons.visibility_outlined),
  monitorRules('profile.section.monitor_rules', Icons.bolt_rounded),
  data('profile.data.title', Icons.storage_outlined),
  settings('profile.section.settings', Icons.tune),
  about('profile.about.title', Icons.info_outline);

  const ProfileSection(this.labelKey, this.icon);

  final String labelKey;
  final IconData icon;

  String label(BuildContext context) => AppLocalizations.of(context).tr(labelKey);

  /* 
  *区段强调色:跟随当前主题色(主区段)或保留语义色(子区段)。
  */
  Color accentOf(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return switch (this) {
      ProfileSection.monitorTopics || ProfileSection.settings => colors.primary,
      ProfileSection.collect || ProfileSection.data => AppColors.info,
      ProfileSection.developers => AppColors.success,
      ProfileSection.monitorRules => AppColors.warning,
      ProfileSection.about => colors.onSurfaceVariant
    };
  }
}
