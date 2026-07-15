import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../shared/widgets/data_provenance_badge.dart';
import '../../../../shared/widgets/page_header.dart';
import '../../application/ai_news_library_providers.dart';
import '../../application/ai_news_providers.dart';
import '../../application/ai_news_reminder_providers.dart';
import 'ai_news_library_filters_dialog.dart';

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
    final readLaterOnly = ref.watch(aiNewsReadLaterOnlyProvider);
    final libraryFilter = ref.watch(aiNewsLibraryFilterProvider);
    final unreadReminders = ref.watch(aiNewsUnreadReminderCountProvider);
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
          icon: unreadReminders > 0 ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
          tooltip: l10n.tr('ai_news.reminders.unread').replaceAll('{count}', '$unreadReminders'),
          onPressed: () => context.go('/ai_news/reminders'),
        ),
        HeaderAction(
          icon: libraryFilter.isActive ? Icons.filter_alt_rounded : Icons.filter_alt_outlined,
          tooltip: l10n.tr('ai_news.filters.title'),
          onPressed: () => showAiNewsLibraryFiltersDialog(context, ref),
        ),
        HeaderAction(
          icon: readLaterOnly ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
          tooltip: l10n.tr(readLaterOnly ? 'ai_news.read_later_show_all' : 'ai_news.read_later_filter'),
          onPressed: () => ref.read(aiNewsReadLaterOnlyProvider.notifier).state = !readLaterOnly,
        ),
        HeaderAction(icon: Icons.refresh_rounded, tooltip: l10n.tr('common.refresh'), onPressed: () => ref.invalidate(aiNewsItemsNotifierProvider))
      ],
    );
  }
}
