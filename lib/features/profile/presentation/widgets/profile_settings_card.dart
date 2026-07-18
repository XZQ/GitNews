import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/breakpoint.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/section_header.dart';
import 'profile_atoms.dart';
import 'profile_preferences_sections.dart';

class ProfileSettingsCard extends ConsumerWidget {
  const ProfileSettingsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final compact = Breakpoints.isCompact(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: l10n.tr('profile.settings.title'), subtitle: l10n.tr('profile.settings.subtitle')),
          const SizedBox(height: AppSpacing.md),
          const ThemeColorPreference(),
          const SizedBox(height: AppSpacing.sm),
          ProfileSettingRow(icon: Icons.dark_mode_outlined, label: l10n.tr('profile.settings.dark_mode'), trailing: const ThemeModePreference(), showIcon: !compact),
          ProfileSettingRow(icon: Icons.translate_outlined, label: l10n.tr('app.language'), trailing: const LanguagePreference(), showIcon: !compact),
          ProfileSettingRow(
            icon: Icons.notifications_none,
            label: l10n.tr('profile.settings.notification'),
            trailing: Text(l10n.tr('profile.settings.notification.enabled'), style: AppTypography.labelMedium),
            onTap: () => context.go('/monitor/settings'),
            showIcon: !compact,
          ),
          ProfileSettingRow(icon: Icons.rocket_launch_outlined, label: l10n.tr('profile.settings.launch_theme'), trailing: const StartupTabPreference(), showIcon: !compact),
          ProfileSettingRow(icon: Icons.cloud_outlined, label: l10n.tr('profile.settings.data_source'), trailing: const TrendingDataSourcePreference(), showIcon: !compact),
          ProfileSettingRow(
            icon: Icons.rss_feed_rounded,
            label: l10n.tr('settings.ai_sources.title'),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: () => context.go('/profile/sources'),
            showIcon: !compact,
          ),
          ProfileSettingRow(
            icon: Icons.cloud_sync_outlined,
            label: l10n.tr('settings.server.title'),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: () => context.go('/profile/server'),
            showIcon: !compact,
          ),
          ProfileSettingRow(icon: Icons.open_in_new_rounded, label: l10n.tr('profile.link_open_mode'), trailing: const LinkOpenModePreference(), showIcon: !compact),
          ProfileSettingRow(
            icon: Icons.code,
            label: l10n.tr('profile.developer_options'),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: () => context.go('/profile/developer'),
            showIcon: !compact,
          )
        ],
      ),
    );
  }
}
