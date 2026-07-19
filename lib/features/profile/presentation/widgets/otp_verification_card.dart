import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_session_controller.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/section_header.dart';
import 'auth_failure_text.dart';

/*
*邮箱 6 位验证码校验页。
*/
class OtpVerificationCard extends ConsumerStatefulWidget {
  const OtpVerificationCard({super.key});

  @override
  ConsumerState<OtpVerificationCard> createState() => _OtpVerificationCardState();
}

class _OtpVerificationCardState extends ConsumerState<OtpVerificationCard> {
  final TextEditingController _codeController = TextEditingController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final state = ref.watch(authSessionControllerProvider);
    final verifying = state.operation == AuthOperation.verifyingCode;
    final seconds = _remainingSeconds(state.resendAvailableAt);
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxxl),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHeader(title: l10n.tr('auth.otp.title'), subtitle: '${l10n.tr('auth.otp.sent_to')} ${state.maskedPendingEmail}'),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _codeController,
                autofocus: true,
                enabled: !verifying,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.oneTimeCode],
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                textAlign: TextAlign.center,
                style: AppTypography.titleLarge.copyWith(letterSpacing: 10),
                decoration: InputDecoration(labelText: l10n.tr('auth.otp.label'), hintText: '000000'),
                onChanged: (_) => ref.read(authSessionControllerProvider.notifier).clearFailure(),
                onSubmitted: (_) => _verify(),
              ),
              const SizedBox(height: AppSpacing.md),
              if (state.failure case final failure?) ...[Text(l10n.tr(authFailureKey(failure)), style: AppTypography.bodySmall.copyWith(color: colors.error)), const SizedBox(height: AppSpacing.md)],
              FilledButton.icon(
                onPressed: verifying ? null : _verify,
                icon: verifying ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.verified_outlined),
                label: Text(l10n.tr(verifying ? 'auth.otp.verifying' : 'auth.otp.verify')),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(onPressed: seconds == 0 && !verifying ? _resend : null, child: Text(seconds == 0 ? l10n.tr('auth.otp.resend') : '${l10n.tr('auth.otp.resend_after')} ${seconds}s')),
              TextButton(onPressed: verifying ? null : () => ref.read(authSessionControllerProvider.notifier).resetChallenge(), child: Text(l10n.tr('auth.otp.change_target'))),
            ],
          ),
        ),
      ],
    );
  }

  /* 校验输入的 6 位验证码。 */
  void _verify() {
    FocusScope.of(context).unfocus();
    ref.read(authSessionControllerProvider.notifier).verifyCode(_codeController.text);
  }

  /* 向当前邮箱重新发送验证码。 */
  void _resend() {
    final state = ref.read(authSessionControllerProvider);
    final email = state.pendingEmail;
    if (email == null) {
      return;
    }
    ref.read(authSessionControllerProvider.notifier).sendEmailCode(email);
  }

  /* 计算验证码重发倒计时。 */
  int _remainingSeconds(DateTime? availableAt) {
    if (availableAt == null) {
      return 0;
    }
    final remaining = availableAt.difference(DateTime.now()).inSeconds;
    return remaining <= 0 ? 0 : remaining + 1;
  }
}
