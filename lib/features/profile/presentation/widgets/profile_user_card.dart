import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_models.dart';
import '../../../../core/auth/auth_session_controller.dart';
import '../../../../core/auth/phone_number.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/shared/local_content_controller.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/breakpoint.dart';
import '../../../../shared/widgets/app_card.dart';

/*
*个人中心顶部用户卡。
*
*应用账号决定登录状态；GitHub API 连接只作为独立的外部数据源状态展示。
*/
class ProfileUserCard extends ConsumerWidget {
  const ProfileUserCard({this.immersive = false, super.key});

  final bool immersive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final auth = ref.watch(authSessionControllerProvider);
    final identity = auth.identity;
    final local = ref.watch(localContentControllerProvider);
    final githubConnected = local.cachedUserName?.isNotEmpty ?? false;
    final signedIn = identity != null;
    final displayName = identity?.displayName ?? l10n.tr('profile.user.anonymous_name');
    final avatarUrl = identity?.avatarUrl;
    final compact = Breakpoints.isCompact(context);
    final initial = displayName.trim().isEmpty ? '?' : displayName.trim().characters.first.toUpperCase();
    final accountStatus = _accountStatus(identity, l10n);

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
              image: avatarUrl == null ? null : DecorationImage(image: NetworkImage(avatarUrl), fit: BoxFit.cover),
            ),
            alignment: Alignment.center,
            child: avatarUrl == null
                ? Text(
                    initial,
                    style: AppTypography.titleMedium.copyWith(color: colors.primary, fontWeight: FontWeight.w800),
                  )
                : null,
          )
        else
          CircleAvatar(
            radius: 32,
            backgroundColor: colors.primaryContainer,
            backgroundImage: avatarUrl == null ? null : NetworkImage(avatarUrl),
            child: avatarUrl == null ? Icon(Icons.person, color: colors.onPrimaryContainer, size: 32) : null,
          ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(displayName, style: AppTypography.titleLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: AppSpacing.xs2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs2, vertical: AppSpacing.xxs),
                    decoration: BoxDecoration(
                      color: signedIn ? colors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                      border: Border.all(color: signedIn ? colors.primary : colors.outlineVariant),
                    ),
                    child: Text(
                      l10n.tr(signedIn ? 'auth.account.badge' : 'profile.signed_out'),
                      style: AppTypography.labelSmall.copyWith(color: signedIn ? colors.onPrimary : colors.onSurfaceVariant, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                accountStatus,
                style: AppTypography.bodySmall.copyWith(color: colors.onSurfaceVariant),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Row(
                children: [
                  Icon(githubConnected ? Icons.link_rounded : Icons.link_off_rounded, size: 14, color: colors.onSurfaceVariant),
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(
                    child: Text(
                      l10n.tr(githubConnected ? 'profile.github.connected' : 'profile.github.not_connected'),
                      style: AppTypography.bodySmall.copyWith(color: colors.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxs),
              TextButton(
                onPressed: auth.isBusy
                    ? null
                    : signedIn
                        ? () => ref.read(authSessionControllerProvider.notifier).signOut()
                        : () => context.push('/profile/login'),
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 28), tapTargetSize: MaterialTapTargetSize.shrinkWrap, alignment: Alignment.centerLeft),
                child: Text(l10n.tr(signedIn ? 'profile.logout' : 'profile.login')),
              ),
            ],
          ),
        ),
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

  /* 生成不泄露完整手机号或邮箱的账号状态文本。 */
  String _accountStatus(AppIdentity? identity, AppLocalizations l10n) {
    if (identity == null) {
      return l10n.tr('profile.user.anonymous_status');
    }
    final phone = maskMainlandPhoneNumber(identity.phone);
    if (phone.isNotEmpty) {
      return '$phone · ${l10n.tr('auth.account.phone_verified')}';
    }
    final email = maskEmailAddress(identity.email);
    if (email.isNotEmpty) {
      return '$email · ${l10n.tr('auth.account.email_verified')}';
    }
    return l10n.tr('auth.account.signed_in');
  }
}
