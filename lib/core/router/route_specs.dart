import 'package:flutter/material.dart';

class TabSpec {
  const TabSpec({
    required this.label,
    required this.pathSegment,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;

  /// 路由路径段(无前导斜杠),用于把 location 解析回 tab index。
  final String pathSegment;
  final IconData icon;
  final IconData selectedIcon;
}

/// 桌面侧栏 7 栏 IA:
/// 总览 → GitHub热榜 → AI 动态 → 技术趋势 → 仓库监控 → 深度报告 → 设置
const List<TabSpec> appTabs = <TabSpec>[
  TabSpec(
    label: '总览',
    pathSegment: 'home',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard_rounded,
  ),
  TabSpec(
    label: 'GitHub热榜',
    pathSegment: 'trending',
    icon: Icons.local_fire_department_outlined,
    selectedIcon: Icons.local_fire_department_rounded,
  ),
  TabSpec(
    label: 'AI 动态',
    pathSegment: 'ai_news',
    icon: Icons.auto_awesome_outlined,
    selectedIcon: Icons.auto_awesome_rounded,
  ),
  TabSpec(
    label: '技术趋势',
    pathSegment: 'tech_hotspot',
    icon: Icons.whatshot_outlined,
    selectedIcon: Icons.whatshot_rounded,
  ),
  TabSpec(
    label: '仓库监控',
    pathSegment: 'monitor',
    icon: Icons.notifications_outlined,
    selectedIcon: Icons.notifications_rounded,
  ),
  TabSpec(
    label: '深度报告',
    pathSegment: 'project',
    icon: Icons.insights_outlined,
    selectedIcon: Icons.insights_rounded,
  ),
  TabSpec(
    label: '设置',
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
