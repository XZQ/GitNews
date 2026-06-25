import 'package:flutter/material.dart';

import '../../core/errors/app_exception.dart';

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
                child: const Text('重试'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  (IconData, String, VoidCallback?) _resolve(BuildContext context) {
    switch (error.kind) {
      case AppExceptionKind.network:
        return (Icons.wifi_off, '网络连接异常,请检查后重试', onRetry);
      case AppExceptionKind.rateLimit:
        final secs = error.retryAfterSeconds ?? 60;
        return (
          Icons.hourglass_bottom,
          '请求过于频繁,$secs 秒后再试',
          onRetry,
        );
      case AppExceptionKind.unauthorized:
        return (Icons.lock_outline, '需要登录', onLogin ?? onRetry);
      case AppExceptionKind.notFound:
        return (Icons.search_off, '未找到资源', onRetry);
      case AppExceptionKind.parse:
      case AppExceptionKind.server:
      case AppExceptionKind.unknown:
        return (Icons.error_outline, '出错了,请稍后重试', onRetry);
    }
  }
}
