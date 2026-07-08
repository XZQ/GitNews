import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/preferences/profile_session_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';

class SidebarProfileMenuButton extends ConsumerWidget {
  const SidebarProfileMenuButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Tooltip(
      message: l10n.tr('common.more'),
      waitDuration: const Duration(milliseconds: 400),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showMenu(context, ref),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm2),
            child: Icon(
              Icons.more_horiz_rounded,
              size: 18,
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  void _showMenu(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    showMenu<void>(
      context: context,
      position: const RelativeRect.fromLTRB(0, 0, 0, 0),
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: colors.outlineVariant),
      ),
      items: [
        PopupMenuItem<void>(
          child: Row(
            children: [
              Icon(
                Icons.settings_outlined,
                size: 18,
                color: colors.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.md),
              Text(l10n.tr('common.settings')),
            ],
          ),
          onTap: () => context.go('/profile'),
        ),
        PopupMenuItem<void>(
          child: Row(
            children: [
              const Icon(
                Icons.logout_rounded,
                size: 18,
                color: AppColors.danger,
              ),
              const SizedBox(width: AppSpacing.md),
              Text(l10n.tr('profile.logout')),
            ],
          ),
          onTap: () async {
            final session = ref.read(profileSessionControllerProvider);
            if (!session.isSignedIn) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.tr('profile.anonymous_hint'))),
              );
              return;
            }
            await ref.read(profileSessionControllerProvider.notifier).signOut();
            if (!context.mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(l10n.tr('profile.logout'))));
          },
        ),
      ],
    );
  }
}
