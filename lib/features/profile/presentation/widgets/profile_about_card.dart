import 'package:flutter/material.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/section_header.dart';
import 'profile_atoms.dart';

class ProfileAboutCard extends StatelessWidget {
  const ProfileAboutCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: l10n.tr('profile.about.title'), subtitle: l10n.tr('profile.about.subtitle')),
          const SizedBox(height: AppSpacing.md),
          ProfileAboutRow(label: l10n.tr('profile.about.version'), value: '0.1.0'),
          ProfileAboutRow(label: l10n.tr('profile.about.build'), value: '2026-06-23'),
          ProfileAboutRow(label: l10n.tr('profile.about.site'), value: 'github-news.app')
        ],
      ),
    );
  }
}
