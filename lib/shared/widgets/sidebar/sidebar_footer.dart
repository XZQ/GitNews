import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/preferences/profile_session_controller.dart';
import '../../../core/shared/local_content_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import 'sidebar_profile_menu_button.dart';

class SidebarFooter extends StatelessWidget {
  const SidebarFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.lg), child: SidebarProfileCard());
  }
}

class SidebarProfileCard extends ConsumerStatefulWidget {
  const SidebarProfileCard({super.key});

  @override
  ConsumerState<SidebarProfileCard> createState() => _SidebarProfileCardState();
}

class _SidebarProfileCardState extends ConsumerState<SidebarProfileCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final session = ref.watch(profileSessionControllerProvider);
    final local = ref.watch(localContentControllerProvider);
    final githubUser = local.cachedUserName;
    final connected = githubUser != null && githubUser.isNotEmpty;
    final signedIn = connected || session.isSignedIn;
    final displayName = connected
        ? githubUser
        : signedIn
            ? session.effectiveName
            : l10n.tr('profile.user.anonymous_name');
    final badge = connected
        ? 'GitHub'
        : signedIn
            ? l10n.tr('profile.session.local_badge')
            : l10n.tr('profile.signed_out');
    final status = connected
        ? l10n.tr('profile.github.connected')
        : signedIn
            ? l10n.tr('profile.session.signed_in')
            : l10n.tr('profile.user.anonymous_status');
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        decoration: BoxDecoration(color: _hovered ? colors.primary.withValues(alpha: 0.08) : colors.surfaceContainerHighest, borderRadius: BorderRadius.circular(AppRadius.md)),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.go('/profile'),
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm2),
              child: Row(
                children: [
                  SidebarProfileAvatar(active: signedIn),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          displayName,
                          style: AppTypography.titleSmall.copyWith(color: colors.onSurface, fontWeight: FontWeight.w700, height: 1.2),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 1),
                              decoration:
                                  BoxDecoration(color: signedIn ? AppColors.starGold.withValues(alpha: 0.16) : colors.surfaceContainerHighest, borderRadius: BorderRadius.circular(AppRadius.xs)),
                              child: Text(
                                badge,
                                style: AppTypography.labelSmall
                                    .copyWith(color: signedIn ? AppColors.warning : colors.onSurfaceVariant, fontWeight: FontWeight.w700, fontSize: 10, letterSpacing: 0, height: 1.2),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Flexible(child: Text(status, style: AppTypography.labelSmall, overflow: TextOverflow.ellipsis))
                          ],
                        )
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const SidebarProfileMenuButton()
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SidebarProfileAvatar extends StatelessWidget {
  const SidebarProfileAvatar({required this.active, super.key});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: AppSpacing.xxl,
      height: AppSpacing.xxl,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(gradient: LinearGradient(colors: [colors.primaryContainer, colors.primary]), borderRadius: BorderRadius.circular(AppRadius.pill)),
            alignment: Alignment.center,
            child: Icon(Icons.person_rounded, size: 18, color: colors.onPrimary),
          ),
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: active ? AppColors.success : colors.outline, shape: BoxShape.circle, border: Border.fromBorderSide(BorderSide(color: colors.surface, width: 2))),
            ),
          )
        ],
      ),
    );
  }
}
