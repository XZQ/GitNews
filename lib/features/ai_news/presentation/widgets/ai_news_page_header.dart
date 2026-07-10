import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../shared/widgets/data_provenance_badge.dart';
import '../../../../shared/widgets/page_header.dart';
import '../../application/ai_news_providers.dart';

/* 
*AI 动态页顶部条 — 复用 [PageHeader] 体系。
*/
class AiNewsPageHeader extends ConsumerWidget {
  const AiNewsPageHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final query = ref.watch(aiNewsSearchQueryProvider);
    final freshness = ref.watch(aiNewsFreshnessProvider);
    return PageHeader(
      title: l10n.tr('ai_news.title'),
      subtitle: l10n.tr('ai_news.subtitle'),
      searchHint: l10n.tr('ai_news.search_hint'),
      searchValue: query,
      onSearchChanged: (v) => ref.read(aiNewsSearchQueryProvider.notifier).state = v,
      onSearchSubmitted: (v) => ref.read(aiNewsSearchQueryProvider.notifier).state = v,
      pills: [DataFreshnessBadge(freshness: freshness)],
      actions: [
        HeaderAction(
          icon: Icons.refresh_rounded,
          tooltip: l10n.tr('common.refresh'),
          onPressed: () => ref.invalidate(aiNewsItemsNotifierProvider),
        ),
      ],
    );
  }
}
