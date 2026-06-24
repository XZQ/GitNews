import 'package:flutter/material.dart';

import '../../core/errors/app_exception.dart';
import '../../core/i18n/app_localizations.dart';

/// 统一错误视图:按 AppException.kind 渲染不同文案与操作。
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
    final (icon, text, action) = _resolve(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            Text(text, style: Theme.of(context).textTheme.bodyMedium),
            if (action != null) ...[
              const SizedBox(height: 16),
              FilledButton(
                onPressed: action,
                child: Text(context.t.t('app.retry')),
              ),
            ],
          ],
        ),
      ),
    );
  }

  (IconData, String, VoidCallback?) _resolve(BuildContext context) {
    final t = context.t;
    switch (error.kind) {
      case AppExceptionKind.network:
        return (Icons.wifi_off, t.t('error.network'), onRetry);
      case AppExceptionKind.rateLimit:
        final secs = error.retryAfterSeconds ?? 60;
        return (
          Icons.hourglass_bottom,
          t.tr('error.rateLimit', {'secs': secs}),
          onRetry,
        );
      case AppExceptionKind.unauthorized:
        return (
          Icons.lock_outline,
          t.t('error.unauthorized'),
          onLogin ?? onRetry
        );
      case AppExceptionKind.notFound:
        return (Icons.search_off, t.t('error.notFound'), onRetry);
      case AppExceptionKind.parse:
      case AppExceptionKind.server:
      case AppExceptionKind.unknown:
        return (Icons.error_outline, t.t('error.generic'), onRetry);
    }
  }
}
