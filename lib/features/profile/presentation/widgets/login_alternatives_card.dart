import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_models.dart';
import '../../../../core/auth/auth_session_controller.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/section_header.dart';
import 'auth_failure_text.dart';

/*
*邮箱、GitHub 和 Google 登录入口。
*/
class LoginAlternativesCard extends ConsumerStatefulWidget {
  const LoginAlternativesCard({super.key});

  @override
  ConsumerState<LoginAlternativesCard> createState() => _LoginAlternativesCardState();
}

class _LoginAlternativesCardState extends ConsumerState<LoginAlternativesCard> {
  final TextEditingController _emailController = TextEditingController();
  bool _showEmail = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final state = ref.watch(authSessionControllerProvider);
    final capabilities = state.capabilities;
    final busy = state.isBusy;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(title: l10n.tr('auth.other.title'), subtitle: l10n.tr('auth.other.subtitle')),
          if (capabilities.email) ...[
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(onPressed: busy ? null : () => setState(() => _showEmail = !_showEmail), icon: const Icon(Icons.mail_outline_rounded), label: Text(l10n.tr('auth.email.continue'))),
            if (_showEmail) ...[
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _emailController,
                enabled: !busy,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.email],
                decoration: InputDecoration(labelText: l10n.tr('auth.email.label'), hintText: l10n.tr('auth.email.hint')),
                onChanged: (_) => ref.read(authSessionControllerProvider.notifier).clearFailure(),
                onSubmitted: (_) => _sendEmail(),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(onPressed: busy ? null : _sendEmail, child: Text(l10n.tr('auth.email.send_code'))),
            ],
          ],
          if (capabilities.github) ...[
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: busy ? null : () => ref.read(authSessionControllerProvider.notifier).signInWithProvider(AppAuthProvider.github),
              icon: const Icon(Icons.code_rounded),
              label: Text(l10n.tr('auth.github.continue')),
            ),
          ],
          if (capabilities.google) ...[
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: busy ? null : () => ref.read(authSessionControllerProvider.notifier).signInWithProvider(AppAuthProvider.google),
              icon: const Icon(Icons.public_rounded),
              label: Text(l10n.tr('auth.google.continue')),
            ),
          ],
          if (!capabilities.email && !capabilities.github && !capabilities.google) ...[
            const SizedBox(height: AppSpacing.md),
            Text(l10n.tr('auth.other.none'), style: AppTypography.bodyMedium.copyWith(color: colors.onSurfaceVariant)),
          ],
          if (state.failure case final failure?) ...[const SizedBox(height: AppSpacing.md), Text(l10n.tr(authFailureKey(failure)), style: AppTypography.bodySmall.copyWith(color: colors.error))],
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.tr('auth.login.disclaimer'),
            style: AppTypography.bodySmall.copyWith(color: colors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /* 发送邮箱验证码。 */
  void _sendEmail() {
    FocusScope.of(context).unfocus();
    ref.read(authSessionControllerProvider.notifier).sendEmailCode(_emailController.text);
  }
}
