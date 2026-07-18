import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/api_endpoints_config.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/preferences/github_token_controller.dart';
import '../../../../core/preferences/profile_session_controller.dart';
import '../../../../core/shared/local_content_controller.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/breakpoint.dart';
import '../../../../shared/widgets/app_card.dart';

/*
 *个人中心顶部用户卡:展示真实 GitHub 身份(Device Flow 登录后回填),
 *未登录时回退到本地匿名会话。
 */
class ProfileUserCard extends ConsumerWidget {
  const ProfileUserCard({this.immersive = false, super.key});

  final bool immersive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final session = ref.watch(profileSessionControllerProvider);
    final local = ref.watch(localContentControllerProvider);
    final githubUser = local.cachedUserName;
    final avatarUrl = local.cachedAvatarUrl;
    final connected = githubUser != null && githubUser.isNotEmpty;
    final displayName = (githubUser != null && githubUser.isNotEmpty) ? githubUser : session.effectiveName;
    final statusKey = connected ? 'profile.github.connected' : session.statusKey;
    final oauthConfigured = ApiEndpointsConfig.githubOAuthConfigured;
    final compact = Breakpoints.isCompact(context);
    final initial = displayName.trim().isEmpty ? '?' : displayName.trim().characters.first.toUpperCase();

    Future<void> signOut() async {
      if (connected) {
        await ref.read(githubTokenControllerProvider.notifier).clear();
        await ref.read(localContentControllerProvider.notifier).clearCachedUser();
      }
      await ref.read(profileSessionControllerProvider.notifier).signOut();
    }

    final content = Row(
      children: [
        if (compact)
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: colors.outlineVariant),
              image: connected && avatarUrl != null ? DecorationImage(image: NetworkImage(avatarUrl), fit: BoxFit.cover) : null,
            ),
            alignment: Alignment.center,
            child: connected && avatarUrl != null ? null : Text(initial, style: AppTypography.titleMedium.copyWith(color: colors.primary, fontWeight: FontWeight.w800)),
          )
        else
          CircleAvatar(
            radius: 32,
            backgroundColor: colors.primaryContainer,
            backgroundImage: connected && avatarUrl != null ? NetworkImage(avatarUrl) : null,
            child: connected && avatarUrl != null ? null : Icon(Icons.person, color: colors.onPrimaryContainer, size: 32),
          ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                      child: Text(
                    displayName,
                    style: AppTypography.titleLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )),
                  const SizedBox(width: AppSpacing.xs2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs2, vertical: AppSpacing.xxs),
                    decoration: BoxDecoration(
                      color: connected ? colors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                      border: Border.all(color: connected ? colors.primary : colors.outlineVariant),
                    ),
                    child: Text(
                      connected ? 'GitHub' : l10n.tr('profile.signed_out'),
                      style: AppTypography.labelSmall.copyWith(color: connected ? colors.onPrimary : colors.onSurfaceVariant, fontWeight: FontWeight.w600),
                    ),
                  )
                ],
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(l10n.tr(statusKey), style: AppTypography.bodySmall.copyWith(color: colors.onSurfaceVariant)),
              const SizedBox(height: AppSpacing.xxs),
              TextButton(
                onPressed: connected ? signOut : () => context.push(oauthConfigured ? '/profile/login' : '/profile/developer'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 28),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  alignment: Alignment.centerLeft,
                ),
                child: Text(connected ? l10n.tr('profile.logout') : l10n.tr(oauthConfigured ? 'profile.login' : 'profile.login.configure_pat')),
              )
            ],
          ),
        )
      ],
    );
    if (compact && immersive) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
        child: content,
      );
    }
    return AppCard(child: content);
  }
}
