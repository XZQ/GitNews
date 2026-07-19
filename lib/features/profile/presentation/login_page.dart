import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_session_controller.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../../shared/widgets/secondary_page_scaffold.dart';
import 'widgets/login_alternatives_card.dart';
import 'widgets/otp_verification_card.dart';

/*
*应用账号登录页。
*
*固定提供邮箱验证码、Google 和 GitHub 三种方式；未接入账号服务的开发构建只保留匿名返回。
*/
class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    ref.listen<AuthSessionState>(authSessionControllerProvider, (previous, next) {
      if (previous?.isAuthenticated != true && next.isAuthenticated) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            context.go('/profile');
          }
        });
      }
    });
    return SecondaryPageScaffold(
      title: l10n.tr('auth.login.title'),
      subtitle: l10n.tr('auth.login.subtitle'),
      icon: Icons.login_rounded,
      fallbackPath: '/profile',
      body: ResponsiveLayout(
        compact: (_) => const _LoginBody(),
        medium: (_) => const CenteredContent(maxWidth: 480, child: _LoginBody()),
        expanded: (_) => const CenteredContent(maxWidth: 480, child: _LoginBody()),
      ),
    );
  }
}

class _LoginBody extends ConsumerWidget {
  const _LoginBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authSessionControllerProvider);
    if (state.pendingEmail != null && (state.operation == AuthOperation.codeSent || state.operation == AuthOperation.verifyingCode)) {
      return const OtpVerificationCard();
    }
    return ListView(padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxxl), children: const [LoginAlternativesCard()]);
  }
}
