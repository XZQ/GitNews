import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../ai_news/application/ai_news_providers.dart';
import '../../../ai_news/domain/ai_news_item.dart';
import '../../../ai_news/presentation/widgets/ai_news_category_style.dart';

class DevIntelSignalsList extends ConsumerWidget {
  const DevIntelSignalsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final items =
        ref.watch(aiNewsItemsNotifierProvider).valueOrNull?.take(4).toList() ??
            const <AiNewsItem>[];
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.tr('devintel.signals.title'),
            style: AppTypography.titleMedium.copyWith(
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (var i = 0; i < items.length; i++) ...[
            _SignalTile(item: items[i]),
            if (i != items.length - 1)
              const SizedBox(height: AppSpacing.lg + AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}

class _SignalTile extends StatelessWidget {
  const _SignalTile({required this.item});

  final AiNewsItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6, right: AppSpacing.md),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: aiNewsCategoryColor(item.category),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.title,
                style: AppTypography.titleSmall.copyWith(
                  color: colors.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${item.source} · ${item.category.label} · ${item.score} ${l10n.tr('devintel.signals.score_suffix')}',
                style: AppTypography.bodySmall.copyWith(
                  color: colors.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
