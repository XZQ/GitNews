import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../application/ai_news_library_providers.dart';
import '../../domain/ai_news_item.dart';
import 'ai_news_item_list.dart';
import 'ai_news_list_skeleton.dart';

class AiNewsSearchResultsBody extends ConsumerWidget {
  const AiNewsSearchResultsBody({required this.query, this.category, super.key});
  final String query;
  final AiNewsCategory? category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = aiNewsLibrarySearchProvider(query);
    return ref
        .watch(provider)
        .when(
          loading: () => const AiNewsListSkeleton(),
          error: (error, _) => ErrorView(error: error.asAppException(), onRetry: () => ref.invalidate(provider)),
          data: (results) {
            void loadMore() => ref.read(provider.notifier).loadMore();
            return AiNewsItemList(
              items: results.items,
              category: category,
              query: query,
              staticList: true,
              searchResults: true,
              onLoadMore: results.hasMore && !results.isLoadingMore && results.loadMoreError == null ? loadMore : null,
              pagingFooter: _SearchFooter(results: results, onLoadMore: loadMore),
            );
          },
        );
  }
}

class _SearchFooter extends StatelessWidget {
  const _SearchFooter({required this.results, required this.onLoadMore});
  final AiNewsSearchResults results;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Column(
        children: [
          Text(l10n.tr('ai_news.search.loaded').replaceAll('{count}', '${results.items.length}')),
          if (results.isLoadingMore)
            const AiNewsLoadMoreIndicator()
          else if (results.hasMore)
            TextButton.icon(
              onPressed: onLoadMore,
              icon: Icon(results.loadMoreError == null ? Icons.expand_more : Icons.refresh),
              label: Text(l10n.tr(results.loadMoreError == null ? 'ai_news.search.load_more' : 'ai_news.search.retry')),
            )
          else
            AiNewsEndOfListFooter(label: l10n.tr('ai_news.no_more')),
        ],
      ),
    );
  }
}
