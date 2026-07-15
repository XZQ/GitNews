import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/github/github_device_flow_controller.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class DeviceFlowContent extends ConsumerWidget {
  const DeviceFlowContent({required this.state, super.key});

  final DeviceFlowState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return switch (state.status) {
      DeviceFlowStatus.idle => _IdleView(l10n: l10n),
      DeviceFlowStatus.awaiting || DeviceFlowStatus.polling => _CodeView(state: state, l10n: l10n),
      DeviceFlowStatus.success => _ResultView(icon: Icons.check_circle_rounded, color: AppColors.success, message: l10n.tr('device_flow.success')),
      DeviceFlowStatus.expired => _retryResult(
          ref,
          l10n,
          icon: Icons.timer_off_rounded,
          color: AppColors.warning,
          messageKey: 'device_flow.expired',
        ),
      DeviceFlowStatus.denied => _retryResult(
          ref,
          l10n,
          icon: Icons.block_rounded,
          color: AppColors.danger,
          messageKey: 'device_flow.denied',
        ),
      DeviceFlowStatus.error => _errorResult(ref, l10n)
    };
  }

  _ResultView _retryResult(
    WidgetRef ref,
    AppLocalizations l10n, {
    required IconData icon,
    required Color color,
    required String messageKey,
  }) {
    return _ResultView(
      icon: icon,
      color: color,
      message: l10n.tr(messageKey),
      retry: l10n.tr('device_flow.retry'),
      onRetry: () => ref.read(githubDeviceFlowProvider.notifier).start(),
    );
  }

  _ResultView _errorResult(WidgetRef ref, AppLocalizations l10n) {
    final notConfigured = state.error == 'not_configured';
    return _ResultView(
      icon: Icons.error_outline_rounded,
      color: AppColors.danger,
      message: l10n.tr(notConfigured ? 'device_flow.not_configured' : 'device_flow.error'),
      hint: notConfigured ? l10n.tr('device_flow.need_config') : null,
      retry: notConfigured ? null : l10n.tr('device_flow.retry'),
      onRetry: notConfigured ? null : () => ref.read(githubDeviceFlowProvider.notifier).start(),
    );
  }
}

class _IdleView extends ConsumerWidget {
  const _IdleView({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Hint(l10n.tr('device_flow.hint_step1')),
        _Hint(l10n.tr('device_flow.hint_step2')),
        _Hint(l10n.tr('device_flow.hint_step3')),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => ref.read(githubDeviceFlowProvider.notifier).start(),
            icon: const Icon(Icons.login_rounded),
            label: Text(l10n.tr('device_flow.start')),
          ),
        )
      ],
    );
  }
}

class _CodeView extends ConsumerWidget {
  const _CodeView({required this.state, required this.l10n});

  final DeviceFlowState state;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final code = state.userCode ?? '';
    final url = state.verificationUriComplete ?? state.verificationUri ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.tr('device_flow.user_code'), style: AppTypography.labelMedium),
        const SizedBox(height: AppSpacing.xs),
        SelectableText(code, style: AppTypography.headlineMedium.copyWith(letterSpacing: 4, color: colors.primary, fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.md),
        if (url.isNotEmpty) ...[
          Text(l10n.tr('device_flow.verification_url'), style: AppTypography.labelMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            url,
            style: AppTypography.bodySmall.copyWith(color: colors.primary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          )
        ],
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
                child: OutlinedButton.icon(
              onPressed: () => _copy(context, code),
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: Text(l10n.tr('device_flow.copy_code')),
            )),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: FilledButton.icon(
                onPressed: url.isEmpty ? null : () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: Text(l10n.tr('device_flow.open_browser')),
              ),
            )
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(width: AppSpacing.sm),
            Text(l10n.tr('device_flow.awaiting')),
            const Spacer(),
            TextButton(onPressed: () => ref.read(githubDeviceFlowProvider.notifier).cancel(), child: Text(l10n.tr('device_flow.cancel')))
          ],
        )
      ],
    );
  }

  void _copy(BuildContext context, String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).tr('device_flow.copied'))));
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({
    required this.icon,
    required this.color,
    required this.message,
    this.hint,
    this.retry,
    this.onRetry,
  });

  final IconData icon;
  final Color color;
  final String message;
  final String? hint;
  final String? retry;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(
            icon,
            color: color,
            size: 28,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(message, style: AppTypography.titleMedium))
        ]),
        if (hint != null) ...[const SizedBox(height: AppSpacing.sm), Text(hint!, style: AppTypography.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant))],
        if (retry != null && onRetry != null) ...[const SizedBox(height: AppSpacing.lg), FilledButton(onPressed: onRetry, child: Text(retry!))]
      ],
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 16,
            color: AppColors.success,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text, style: AppTypography.bodyMedium))
        ],
      ),
    );
  }
}
