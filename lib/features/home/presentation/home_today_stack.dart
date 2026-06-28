import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_card.dart';
import 'home_chart_helpers.dart';

/// 右侧"今日"卡片栈,根据分类切换显示不同指标。
class HomeTodayStack extends StatelessWidget {
  const HomeTodayStack({required this.tab, super.key});

  final HomeLegacyTab tab;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final cards = switch (tab) {
      HomeLegacyTab.trending => [
          const _TodayCard(
            icon: Icons.star_rounded,
            iconColor: AppColors.starGold,
            label: '今日 Star 增长',
            value: '4,231',
            delta: '+18.5%',
            items: 3,
          ),
          const _TodayCard(
            icon: Icons.forum_outlined,
            iconColor: AppColors.info,
            label: '今日讨论',
            value: '1,827',
            delta: '+9.2%',
            items: 2,
          ),
          const _TodayCard(
            icon: Icons.commit_rounded,
            iconColor: AppColors.success,
            label: '今日 Commits',
            value: '12,940',
            delta: '+4.1%',
            items: 4,
          ),
        ],
      HomeLegacyTab.growth => [
          const _TodayCard(
            icon: Icons.trending_up_rounded,
            iconColor: AppColors.success,
            label: '最快增长仓库',
            value: '+62.4%',
            delta: 'llama.cpp',
            items: 1,
          ),
          _TodayCard(
            icon: Icons.show_chart_rounded,
            iconColor: primary,
            label: '增长中仓库',
            value: '1,284',
            delta: '+96',
            items: 2,
          ),
          const _TodayCard(
            icon: Icons.warning_amber_rounded,
            iconColor: AppColors.warning,
            label: '增速回落',
            value: '5',
            delta: '需关注',
            items: 3,
          ),
        ],
      HomeLegacyTab.health => [
          _TodayCard(
            icon: Icons.people_rounded,
            iconColor: primary,
            label: '活跃贡献者',
            value: '8.2K',
            delta: '+4.1%',
            items: 1,
          ),
          const _TodayCard(
            icon: Icons.commit_rounded,
            iconColor: AppColors.success,
            label: '今日 Commits',
            value: '12,940',
            delta: '+4.1%',
            items: 2,
          ),
          const _TodayCard(
            icon: Icons.support_agent_rounded,
            iconColor: AppColors.info,
            label: 'Issue 响应中位',
            value: '6.4h',
            delta: '-0.8h',
            items: 3,
          ),
        ],
      HomeLegacyTab.starred => [
          _TodayCard(
            icon: Icons.bookmark_rounded,
            iconColor: primary,
            label: '收藏仓库',
            value: '24',
            delta: '+3',
            items: 1,
          ),
          const _TodayCard(
            icon: Icons.star_rounded,
            iconColor: AppColors.starGold,
            label: '近 7 日 Star',
            value: '1,840',
            delta: '+12.8%',
            items: 2,
          ),
          const _TodayCard(
            icon: Icons.notifications_active_outlined,
            iconColor: AppColors.warning,
            label: '待跟进',
            value: '6',
            delta: '-1',
            items: 3,
          ),
        ],
    };
    return Column(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          cards[i],
          if (i != cards.length - 1) const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.delta,
    required this.items,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String delta;
  final int items;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.labelMedium.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          value,
                          style: AppTypography.headlineMedium,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      delta,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$items',
              style: AppTypography.labelSmall.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
