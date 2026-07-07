import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../i18n/app_localizations.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/* 未匹配路由兜底页。 */
/*  */
/* 设计要点(对应 CLAUDE.md §九): */
/* - 静态展示错误页,**不**自动跳首页 —— 让用户能识别深链失效,而不是被默默重定向。 */
/* - 不渲染 `error.toString()`(可能含内部路径 / URL / 异常类型,信息泄露)。 */
/*   仅在 debug 模式下走 `debugPrint`(release 被 strip)。 */
class RouteErrorView extends StatelessWidget {
  const RouteErrorView({required this.error, super.key});

  final Exception? error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (error != null) {
      debugPrint('RouteErrorView: $error');
    }
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.home_rounded),
          onPressed: () => context.go('/home'),
        ),
        title: Text(l10n.tr('route_error.title')),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search_off_rounded, size: 56),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.tr('route_error.unable_to_open'),
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.tr('route_error.hint'),
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: () => context.go('/home'),
                child: Text(l10n.tr('route_error.back_home')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
