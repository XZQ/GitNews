import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_session_controller.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/section_header.dart';
import 'auth_failure_text.dart';

/*
*中国大陆手机号验证码主入口。
*/
class PhoneLoginCard extends ConsumerStatefulWidget {
  const PhoneLoginCard({super.key});

  @override
  ConsumerState<PhoneLoginCard> createState() => _PhoneLoginCardState();
}

class _PhoneLoginCardState extends ConsumerState<PhoneLoginCard> {
  final TextEditingController _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final state = ref.watch(authSessionControllerProvider);
    final phoneEnabled = state.capabilities.isConfigured && state.capabilities.phone;
    final sending = state.operation == AuthOperation.sendingCode;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(title: l10n.tr('auth.phone.title'), subtitle: l10n.tr('auth.phone.subtitle')),
          const SizedBox(height: AppSpacing.lg),
          if (phoneEnabled) ...[
            TextField(
              controller: _phoneController,
              enabled: !sending,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.telephoneNumberNational],
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11)],
              decoration: InputDecoration(labelText: l10n.tr('auth.phone.label'), hintText: l10n.tr('auth.phone.hint'), prefixText: '+86 '),
              onChanged: (_) => ref.read(authSessionControllerProvider.notifier).clearFailure(),
              onSubmitted: (_) => _send(),
            ),
            const SizedBox(height: AppSpacing.md),
            if (state.failure case final failure?) ...[Text(l10n.tr(authFailureKey(failure)), style: AppTypography.bodySmall.copyWith(color: colors.error)), const SizedBox(height: AppSpacing.md)],
            FilledButton.icon(
              onPressed: sending ? null : _send,
              icon: sending ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.sms_outlined),
              label: Text(l10n.tr(sending ? 'auth.phone.sending' : 'auth.phone.send_code')),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(color: colors.surfaceContainerHighest, borderRadius: BorderRadius.circular(AppRadius.md)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, size: 20, color: colors.onSurfaceVariant),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      l10n.tr(state.capabilities.isConfigured ? 'auth.phone.disabled' : 'auth.unconfigured.message'),
                      style: AppTypography.bodyMedium.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          TextButton(onPressed: () => context.go('/profile'), child: Text(l10n.tr('auth.continue_anonymous'))),
        ],
      ),
    );
  }

  /* 提交手机号并发送验证码。 */
  void _send() {
    FocusScope.of(context).unfocus();
    ref.read(authSessionControllerProvider.notifier).sendPhoneCode(_phoneController.text);
  }
}
