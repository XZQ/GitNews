import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/section_header.dart';
import '../../project/application/project_providers.dart';
import '../../repo_detail/domain/entities.dart';
import '../../tech_hotspot/application/tech_hotspot_providers.dart';

/* 
*话题 / 推荐主题(手机首页底栏 + 桌面尾栏共用)。
*/
class HomeTopicsPanel extends ConsumerWidget {
  const HomeTopicsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final topics = ref.watch(techHotspotDigestProvider).maybeWhen(
          data: (digest) => digest.hotTags.take(10).toList(),
          orElse: () => _fallbackTopics(l10n),
        );
    final contributors = ref.watch(projectDigestProvider).maybeWhen(
          data: (digest) => digest.contributors.take(5).toList(),
          orElse: () => const <ContributorEntity>[],
        );
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
              for (final topic in topics) _TopicChip(label: topic),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SectionHeader(
            title: l10n.tr('home.section.devs.title'),
            subtitle: l10n.tr('home.section.devs.subtitle'),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final c in contributors)
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

  List<String> _fallbackTopics(AppLocalizations l10n) {
    return [
      l10n.tr('home.topic.agents'),
      l10n.tr('home.topic.llm'),
      l10n.tr('home.topic.devtools'),
      l10n.tr('home.topic.rag'),
      l10n.tr('home.topic.web3'),
      l10n.tr('home.topic.security'),
      l10n.tr('home.topic.cloud_native'),
      l10n.tr('home.topic.data_infra'),
    ];
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
