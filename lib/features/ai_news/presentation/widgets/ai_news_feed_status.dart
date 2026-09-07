import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/data_freshness.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/ai_news_providers.dart';

/// Describes this list's provenance independently of the daily report.
class AiNewsFeedStatus extends ConsumerWidget {
  const AiNewsFeedStatus({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final freshness = ref.watch(aiNewsFreshnessProvider);
    final at = ref.watch(aiNewsLastValidatedAtProvider);
    final local = at?.toLocal();
    final time = local == null ? '' : '${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} ${TimeOfDay.fromDateTime(local).format(context)}';
    final l10n = AppLocalizations.of(context);
    final label = switch (freshness) {
      DataFreshness.live => 'ai_news.feed_live',
      DataFreshness.freshCache => 'ai_news.feed_cached',
      DataFreshness.staleCache => 'ai_news.feed_stale',
      DataFreshness.seed => 'ai_news.feed_seed',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
      child: Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.xxs,
        children: [
          Text(l10n.tr(label), style: AppTypography.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          if (at != null && freshness != DataFreshness.seed) Text(l10n.tr('ai_news.feed_checked').replaceAll('{time}', time), style: AppTypography.bodySmall),
        ],
      ),
    );
  }
}
