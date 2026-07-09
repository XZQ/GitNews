import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/section_header.dart';
import 'profile_atoms.dart';

class ProfileCollectDetailCard extends StatelessWidget {
  const ProfileCollectDetailCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: l10n.tr('profile.section.collect'),
            subtitle: l10n.tr('profile.detail.collect.subtitle'),
          ),
          const SizedBox(height: AppSpacing.md),
          ProfileDetailRow(
            icon: Icons.bookmark_outline,
            iconColor: AppColors.info,
            label: l10n.tr('profile.detail.collect.count').replaceAll('{n}', '12'),
            value: l10n.tr('profile.detail.collect.all'),
          ),
          const Divider(height: 1),
          ProfileDetailRow(
            icon: Icons.history,
            iconColor: isLight ? AppColors.textSecondaryLight : AppColors.textSecondaryDark,
            label: l10n.tr('profile.detail.collect.recent'),
            value: 'agent · llm · devops',
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: () => context.go('/profile/collect'),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: Text(l10n.tr('profile.detail.collect.open')),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileDevelopersDetailCard extends StatelessWidget {
  const ProfileDevelopersDetailCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: l10n.tr('profile.section.developers'),
            subtitle: l10n.tr('profile.detail.developers.subtitle'),
          ),
          const SizedBox(height: AppSpacing.md),
          ProfileDetailRow(
            icon: Icons.people_outline,
            iconColor: AppColors.success,
            label: l10n.tr('profile.detail.developers.count').replaceAll('{n}', '8'),
            value: l10n.tr('profile.detail.collect.all'),
          ),
          const Divider(height: 1),
          ProfileDetailRow(
            icon: Icons.notifications_active_outlined,
            iconColor: AppColors.warning,
            label: l10n.tr('profile.detail.developers.notify'),
            value: 'Star / Fork / Release',
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: () => context.go('/profile/developers'),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: Text(l10n.tr('profile.detail.developers.open')),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileMonitorTopicsDetailCard extends StatelessWidget {
  const ProfileMonitorTopicsDetailCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: l10n.tr('profile.section.monitor_topics'),
            subtitle: l10n.tr('profile.detail.monitor_topics.subtitle'),
          ),
          const SizedBox(height: AppSpacing.md),
          ProfileDetailRow(
            icon: Icons.visibility_outlined,
            iconColor: Theme.of(context).colorScheme.primary,
            label: l10n.tr('profile.detail.monitor_topics.count').replaceAll('{n}', '5'),
            value: l10n.tr('profile.detail.collect.all'),
          ),
          const Divider(height: 1),
          ProfileDetailRow(
            icon: Icons.timeline,
            iconColor: AppColors.info,
            label: l10n.tr('profile.detail.monitor_topics.recent'),
            value: l10n.tr('profile.detail.monitor_topics.unread').replaceAll('{n}', '2'),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: () => context.go('/profile/monitor'),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: Text(l10n.tr('profile.detail.monitor_topics.open')),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileMonitorRulesDetailCard extends StatelessWidget {
  const ProfileMonitorRulesDetailCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: l10n.tr('profile.section.monitor_rules'),
            subtitle: l10n.tr('profile.detail.monitor_rules.subtitle'),
          ),
          const SizedBox(height: AppSpacing.md),
          ProfileDetailRow(
            icon: Icons.bolt_rounded,
            iconColor: AppColors.warning,
            label: 'Star 增速 ≥ 30 / 天',
            value: l10n.tr('profile.detail.monitor_rules.enabled'),
          ),
          const Divider(height: 1),
          ProfileDetailRow(
            icon: Icons.bolt_rounded,
            iconColor: AppColors.warning,
            label: 'Issue 数小时 ≥ 5',
            value: l10n.tr('profile.detail.monitor_rules.enabled'),
          ),
          const Divider(height: 1),
          ProfileDetailRow(
            icon: Icons.bolt_rounded,
            iconColor: AppColors.warning,
            label: '新 Release',
            value: l10n.tr('profile.detail.monitor_rules.enabled'),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: () => context.go('/profile/rules'),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: Text(l10n.tr('profile.detail.monitor_rules.manage')),
            ),
          ),
        ],
      ),
    );
  }
}
