import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/preferences/profile_session_controller.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_card.dart';

class ProfileUserCard extends ConsumerWidget {
  const ProfileUserCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final session = ref.watch(profileSessionControllerProvider);
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colors.primaryContainer, colors.primary],
              ),
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.person, color: colors.onPrimary, size: 32),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      session.effectiveName,
                      style: AppTypography.titleLarge,
                    ),
                    const SizedBox(width: AppSpacing.xs2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs2,
                        vertical: AppSpacing.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                      child: Text(
                        'PRO',
                        style: AppTypography.labelSmall.copyWith(
                          color: colors.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  l10n.tr(session.statusKey),
                  style: AppTypography.bodySmall.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                TextButton(
                  onPressed: session.isSignedIn
                      ? () => ref
                          .read(profileSessionControllerProvider.notifier)
                          .signOut()
                      : () => context.go('/login'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 28),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    alignment: Alignment.centerLeft,
                  ),
                  child: Text(
                    session.isSignedIn ? '退出登录' : l10n.tr('profile.login'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
