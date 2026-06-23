import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/demo_data.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/repo_tile.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/app_card.dart';

/// Star 增长榜 Top 列表(手机首页 + 桌面右栏共用)。
class HomeTrendingPanel extends StatelessWidget {
  const HomeTrendingPanel({
    this.showHeader = true,
    this.maxItems = 5,
    super.key,
  });

  final bool showHeader;
  final int maxItems;

  @override
  Widget build(BuildContext context) {
    final items = DemoData.trending.take(maxItems).toList();
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          if (showHeader)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xs,
              ),
              child: SectionHeader(
                title: 'Star Growth Ranking',
                subtitle: 'Top ${items.length} Star velocity today',
                trailing: const _FilterChip(text: '今日'),
                onTap: () => context.go('/trending'),
              ),
            ),
          for (var i = 0; i < items.length; i++) ...[
            if (i != 0) const Divider(height: 1),
            RepoTile(
              repo: items[i],
              onTap: () => context.go(
                '/repo_detail/${Uri.encodeComponent(items[i].fullName)}',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: colors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
