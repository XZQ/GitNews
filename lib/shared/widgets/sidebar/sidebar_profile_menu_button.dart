import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_session_controller.dart';
import '../../../core/i18n/app_localizations.dart';
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
            child: Icon(Icons.more_horiz_rounded, size: 18, color: colors.onSurfaceVariant),
          ),
        ),
      ),
    );
  }

  void _showMenu(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final signedIn = ref.read(authSessionControllerProvider).isAuthenticated;
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
              Icon(Icons.settings_outlined, size: 18, color: colors.onSurfaceVariant),
              const SizedBox(width: AppSpacing.md),
              Text(l10n.tr('common.settings')),
            ],
          ),
          onTap: () => context.go('/profile/preferences'),
        ),
        PopupMenuItem<void>(
          child: Row(
            children: [
              Icon(signedIn ? Icons.logout_rounded : Icons.login_rounded, size: 18, color: signedIn ? AppColors.danger : colors.primary),
              const SizedBox(width: AppSpacing.md),
              Text(l10n.tr(signedIn ? 'profile.logout' : 'profile.login')),
            ],
          ),
          onTap: () async {
            if (!signedIn) {
              context.go('/profile/login');
              return;
            }
            await ref.read(authSessionControllerProvider.notifier).signOut();
            if (!context.mounted) {
              return;
            }
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.tr('profile.logout'))));
          },
        ),
      ],
    );
  }
}
