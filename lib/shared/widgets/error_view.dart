import 'package:flutter/material.dart';

import '../../core/errors/app_exception.dart';
import '../../core/i18n/app_localizations.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/* 
*统一错误视图:按 AppException.kind 渲染不同文案与操作。
*/
class ErrorView extends StatelessWidget {
  const ErrorView({
    required this.error,
    this.onRetry,
    this.onLogin,
    super.key,
  });

  final AppException error;
  final VoidCallback? onRetry;
  final VoidCallback? onLogin;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (icon, text, action) = _resolve(context, l10n);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: AppSpacing.xxxl,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(text, style: AppTypography.bodyMedium),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: action,
                child: Text(l10n.tr('common.retry')),
              ),
            ],
          ],
        ),
      ),
    );
  }

  (IconData, String, VoidCallback?) _resolve(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    switch (error.kind) {
      case AppExceptionKind.network:
        return (Icons.wifi_off, l10n.tr('error_view.network'), onRetry);
      case AppExceptionKind.rateLimit:
        final secs = error.retryAfterSeconds ?? 60;
        final unit = l10n
            .tr('error_view.retry_after_seconds')
            .replaceAll('{seconds}', secs.toString());
        return (
          Icons.hourglass_bottom,
          '${l10n.tr('error_view.rate_limit')} ($unit)',
          onRetry,
        );
      case AppExceptionKind.unauthorized:
        return (
          Icons.lock_outline,
          l10n.tr('error_view.unauthorized'),
          onLogin ?? onRetry,
        );
      case AppExceptionKind.notFound:
        return (Icons.search_off, l10n.tr('error_view.not_found'), onRetry);
      case AppExceptionKind.parse:
        return (Icons.error_outline, l10n.tr('error_view.parse'), onRetry);
      case AppExceptionKind.server:
        return (Icons.error_outline, l10n.tr('error_view.server'), onRetry);
      case AppExceptionKind.cache:
        return (Icons.error_outline, l10n.tr('error_view.cache'), onRetry);
      case AppExceptionKind.unknown:
        return (Icons.error_outline, l10n.tr('error_view.unknown'), onRetry);
    }
  }
}
