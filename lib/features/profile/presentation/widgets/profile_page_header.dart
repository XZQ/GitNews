import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/page_header.dart';

/* 
*设置页顶部条。
*/
class ProfilePageHeader extends StatelessWidget {
  const ProfilePageHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PageHeader(
      icon: Icons.person_outline_rounded,
      iconAccent: AppColors.starGold,
      title: l10n.tr('profile.title'),
      subtitle: l10n.tr('profile.subtitle.short'),
      actions: [
        HeaderAction(
          icon: Icons.settings_outlined,
          tooltip: l10n.tr('profile.title'),
          onPressed: () => context.go('/profile'),
        ),
      ],
    );
  }
}
