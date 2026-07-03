import 'package:flutter/material.dart';

import '../../../core/demo_data.dart';
import '../../../core/i18n/app_localizations.dart';
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
    'home.topic.agents',
    'home.topic.llm',
    'home.topic.devtools',
    'home.topic.rag',
    'home.topic.web3',
    'home.topic.security',
    'home.topic.cloud_native',
    'home.topic.data_infra',
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: l10n.tr('home.section.topics.title'),
            subtitle: l10n.tr('home.section.topics.subtitle'),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final topic in _topics) _TopicChip(label: l10n.tr(topic)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SectionHeader(
            title: l10n.tr('home.section.devs.title'),
            subtitle: l10n.tr('home.section.devs.subtitle'),
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
                '+${c.contributions} ${l10n.tr('home.contrib.week')}',
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
