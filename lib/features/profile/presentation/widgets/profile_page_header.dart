import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
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
      pills: const [_ProPill()],
      actions: [
        IconButton(
          tooltip: l10n.tr('profile.title'),
          onPressed: () => context.go('/profile'),
          icon: const Icon(Icons.settings_outlined, size: 20),
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        ),
      ],
    );
  }
}

class _ProPill extends StatelessWidget {
  const _ProPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs2,
      ),
      decoration: BoxDecoration(
        color: AppColors.starGold.withValues(alpha: 0.16),
        border: Border.all(color: AppColors.starGold.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.workspace_premium_outlined,
            size: AppSpacing.md,
            color: AppColors.warning,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'PRO',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.warning,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
