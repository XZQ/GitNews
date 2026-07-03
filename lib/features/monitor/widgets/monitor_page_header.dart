import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/page_header.dart';
import '../domain/entities.dart';

/// 监控页顶部条。
class MonitorPageHeader extends StatelessWidget {
  const MonitorPageHeader({required this.stats, super.key});

  final MonitorStats stats;

  @override
  Widget build(BuildContext context) {
    return PageHeader(
      icon: Icons.radar_rounded,
      iconAccent: AppColors.success,
      title: '监控',
      subtitle: '实时告警与仓库动态',
      searchHint: '搜索仓库、告警、规则...',
      onSearchSubmitted: (v) {
        if (v.trim().isEmpty) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('监控搜索即将接入')),
        );
      },
      pills: [
        HeaderStatPill(
          icon: Icons.circle,
          label: '${stats.unreadAlertCount} 未读',
          color: AppColors.success,
        ),
      ],
      actions: [
        IconButton(
          tooltip: '新增监控',
          onPressed: () => context.go('/profile/monitor'),
          icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        ),
      ],
    );
  }
}
