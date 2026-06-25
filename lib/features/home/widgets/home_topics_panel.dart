import 'package:flutter/material.dart';

import '../../../core/demo_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/section_header.dart';

/// 话题 / 推荐主题(手机首页底栏 + 桌面尾栏共用)。
class HomeTopicsPanel extends StatelessWidget {
  const HomeTopicsPanel({super.key});

  static const _topics = [
    'AI 智能体',
    '大语言模型',
    '开发工具',
    '检索增强生成',
    'Web3',
    '安全',
    '云原生',
    '数据基建',
  ];

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: '热门话题',
            subtitle: '基于本周 Star 增速与讨论热度',
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final topic in _topics) _TopicChip(label: topic),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(
            title: '可关注的开发者',
            subtitle: '本周 Star 增长贡献 Top 5',
          ),
          const SizedBox(height: AppSpacing.md),
          for (final c in DemoData.contributors)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.brandLight,
                child: Text(
                  c.login[0].toUpperCase(),
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.brandDark,
                  ),
                ),
              ),
              title: Text(c.login, style: AppTypography.titleSmall),
              subtitle: Text(
                '+${c.contributions} 本周贡献',
              ),
              trailing: const Icon(Icons.chevron_right, size: 18),
            ),
        ],
      ),
    );
  }
}

class _TopicChip extends StatelessWidget {
  const _TopicChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: AppTypography.labelMedium.copyWith(
          color: colors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
