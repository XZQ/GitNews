import 'package:flutter/material.dart';

class TabSpec {
  const TabSpec({
    required this.labelKey,
    required this.pathSegment,
    required this.icon,
    required this.selectedIcon,
  });

  // i18n key,渲染时由调用方通过 [AppLocalizations.tr] 解析为本地化文案。
  final String labelKey;

  // 路由路径段(无前导斜杠),用于把 location 解析回 tab index。
  final String pathSegment;
  final IconData icon;
  final IconData selectedIcon;
}

// 桌面侧栏 7 栏 IA:
// 总览 → AI 动态 → GitHub热榜 → AI雷达 → 仓库监控 → 深度报告 → 设置
const List<TabSpec> appTabs = <TabSpec>[
  TabSpec(
    labelKey: 'tab.home',
    pathSegment: 'home',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard_rounded,
  ),
  TabSpec(
    labelKey: 'tab.ai_news',
    pathSegment: 'ai_news',
    icon: Icons.auto_awesome_outlined,
    selectedIcon: Icons.auto_awesome_rounded,
  ),
  TabSpec(
    labelKey: 'tab.trending',
    pathSegment: 'trending',
    icon: Icons.local_fire_department_outlined,
    selectedIcon: Icons.local_fire_department_rounded,
  ),
  TabSpec(
    labelKey: 'tab.tech_hotspot',
    pathSegment: 'tech_hotspot',
    icon: Icons.device_hub_outlined,
    selectedIcon: Icons.device_hub_rounded,
  ),
  TabSpec(
    labelKey: 'tab.monitor',
    pathSegment: 'monitor',
    icon: Icons.notifications_outlined,
    selectedIcon: Icons.notifications_rounded,
  ),
  TabSpec(
    labelKey: 'tab.project',
    pathSegment: 'project',
    icon: Icons.insights_outlined,
    selectedIcon: Icons.insights_rounded,
  ),
  TabSpec(
    labelKey: 'tab.profile',
    pathSegment: 'profile',
    icon: Icons.person_outline,
    selectedIcon: Icons.person_rounded,
  ),
];

extension TabIndexLookup on List<TabSpec> {
  int indexOfLocation(String location) {
    for (var i = 0; i < length; i++) {
      final segment = this[i].pathSegment;
      if (location == '/$segment' ||
          location.startsWith('/$segment/') ||
          location.startsWith('/$segment?')) {
        return i;
      }
    }
    return 0;
  }
}
