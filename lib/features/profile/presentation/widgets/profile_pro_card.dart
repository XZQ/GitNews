import 'package:flutter/material.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/section_header.dart';
import 'profile_atoms.dart';

class ProfileProCard extends StatelessWidget {
  const ProfileProCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: l10n.tr('profile.pro.title'),
            subtitle: l10n.tr('profile.pro.subtitle'),
          ),
          const SizedBox(height: AppSpacing.md),
          ProfileBullet(l10n.tr('profile.pro.bullet.unlimited')),
          ProfileBullet(l10n.tr('profile.pro.bullet.alerts')),
          ProfileBullet(l10n.tr('profile.pro.bullet.export')),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.tr('profile.pro.noti'))),
                );
              },
              child: Text(l10n.tr('profile.pro.upgrade')),
            ),
          ),
        ],
      ),
    );
  }
}
