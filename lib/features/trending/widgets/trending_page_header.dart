import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/page_header.dart';
import '../application/trending_providers.dart';

/// 趋势页顶部条:与其它一级页共享同一规格。
class TrendingPageHeader extends ConsumerWidget {
  const TrendingPageHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PageHeader(
      icon: Icons.trending_up_rounded,
      iconAccent: AppColors.info,
      title: 'GitHub热榜',
      subtitle: 'Star 增速榜 · 仓库发现',
      searchHint: '搜索仓库、语言、主题...',
      onSearchSubmitted: (v) {
        if (v.trim().isEmpty) return;
        context.go('/trending/repos');
      },
      pills: const [
        HeaderStatPill(
          icon: Icons.local_fire_department_rounded,
          label: '今日 +124',
          color: AppColors.success,
        ),
      ],
      actions: [
        IconButton(
          tooltip: '刷新',
          onPressed: () => ref.invalidate(trendingDigestProvider),
          icon: const Icon(Icons.refresh_rounded, size: 20),
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        ),
      ],
    );
  }
}
