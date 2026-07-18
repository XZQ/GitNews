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
import 'widgets/phone_login_card.dart';

/*
*应用账号登录页。
*
*国内手机号为首要方式；邮箱、GitHub、Google 只在发布构建显式启用后展示。
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
    if (state.challengeKind != null && (state.operation == AuthOperation.codeSent || state.operation == AuthOperation.verifyingCode)) {
      return const OtpVerificationCard();
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxxl),
      children: const [
        PhoneLoginCard(),
        SizedBox(height: AppSpacing.lg),
        LoginAlternativesCard(),
      ],
    );
  }
}
