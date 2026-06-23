import 'package:flutter/material.dart';

import '../../../core/demo_data.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/section_header.dart';

/// 话题 / 推荐主题(手机首页底栏 + 桌面尾栏共用)。
class HomeTopicsPanel extends StatelessWidget {
  const HomeTopicsPanel({super.key});

  static const _topics = [
    'AI Agent',
    'LLM',
    'DevTools',
    'RAG',
    'Web3',
    'Security',
    'Cloud Native',
    'Data Infra',
  ];

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Hot Topics',
            subtitle: 'Based on weekly Star velocity and discussion heat',
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final t in _topics) _TopicChip(label: t),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(
            title: 'Developers to Follow',
            subtitle: 'Top 5 Star contributors this week',
          ),
          const SizedBox(height: AppSpacing.md),
          for (final c in DemoData.contributors)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFFEEEAFE),
                child: Text(
                  c.login[0].toUpperCase(),
                  style: AppTypography.labelMedium.copyWith(
                    color: const Color(0xFF5840B5),
                  ),
                ),
              ),
              title: Text(c.login, style: AppTypography.titleSmall),
              subtitle: Text('+${c.contributions} 本周贡献'),
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
