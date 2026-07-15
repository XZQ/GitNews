import 'package:flutter/material.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';

class TechHotspotDetailSectionError extends StatelessWidget {
  const TechHotspotDetailSectionError({
    required this.title,
    required this.error,
    required this.onRetry,
    super.key,
  });

  final String title;
  final AppException error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.errorContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: colors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: colors.error, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                Text(
                  _messageFor(l10n, error),
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                )
              ],
            ),
          ),
          TextButton(onPressed: onRetry, style: TextButton.styleFrom(foregroundColor: AppColors.brand), child: Text(l10n.tr('common.retry')))
        ],
      ),
    );
  }
}

String _messageFor(AppLocalizations l10n, AppException error) {
  switch (error.kind) {
    case AppExceptionKind.network:
      return l10n.tr('tech_hotspot.error.network');
    case AppExceptionKind.rateLimit:
      final secs = error.retryAfterSeconds ?? 60;
      return l10n.tr('tech_hotspot.error.rate_limit').replaceAll('{secs}', secs.toString());
    case AppExceptionKind.unauthorized:
      return l10n.tr('tech_hotspot.error.unauthorized');
    case AppExceptionKind.notFound:
      return l10n.tr('tech_hotspot.error.not_found');
    case AppExceptionKind.parse:
    case AppExceptionKind.server:
    case AppExceptionKind.cache:
    case AppExceptionKind.unknown:
      return l10n.tr('tech_hotspot.error.unknown');
  }
}
