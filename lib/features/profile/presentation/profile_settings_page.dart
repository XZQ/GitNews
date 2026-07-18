import 'package:flutter/material.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../../shared/widgets/secondary_page_scaffold.dart';
import 'widgets/profile_about_card.dart';
import 'widgets/profile_data_card.dart';
import 'widgets/profile_settings_card.dart';

class ProfileSettingsPage extends StatelessWidget {
  const ProfileSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SecondaryPageScaffold(
      title: l10n.tr('profile.mobile_settings.title'),
      icon: Icons.tune_rounded,
      fallbackPath: '/profile',
      body: ResponsiveLayout(
        compact: (_) => const _SettingsBody(),
        medium: (_) => const CenteredContent(child: _SettingsBody()),
        expanded: (_) => const CenteredContent(child: _SettingsBody()),
      ),
    );
  }
}

class _SettingsBody extends StatelessWidget {
  const _SettingsBody();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      children: const [
        ProfileSettingsCard(),
        SizedBox(height: AppSpacing.lg),
        ProfileDataCard(),
        SizedBox(height: AppSpacing.lg),
        ProfileAboutCard(),
      ],
    );
  }
}
