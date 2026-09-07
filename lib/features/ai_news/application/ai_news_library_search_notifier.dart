import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/ai_news_item.dart';
import 'ai_news_library_providers.dart';
import 'ai_news_providers.dart';

const aiNewsLibraryPageSize = 50;

final aiNewsLibrarySearchProvider = AsyncNotifierProvider.autoDispose.family<AiNewsLibrarySearchNotifier, AiNewsSearchResults, String>(AiNewsLibrarySearchNotifier.new);

class AiNewsSearchResults {
  const AiNewsSearchResults({required this.items, required this.hasMore, required this.nextOffset, this.isLoadingMore = false, this.loadMoreError});

  final List<AiNewsItem> items;
  final bool hasMore;
  final int nextOffset;
  final bool isLoadingMore;
  final Object? loadMoreError;
}

/// Pages the entire local library and keeps existing results available on failure.
class AiNewsLibrarySearchNotifier extends AsyncNotifier<AiNewsSearchResults> {
  AiNewsLibrarySearchNotifier(this.query);
  final String query;
  int _generation = 0;

  @override
  Future<AiNewsSearchResults> build() async {
    _generation++;
    final category = ref.watch(aiNewsCategoryFilterProvider);
    final filter = ref.watch(aiNewsLibraryFilterProvider);
    final dao = ref.watch(aiNewsCacheDaoProvider);
    final items = await dao.searchAll(query, category: category, filter: filter, limit: aiNewsLibraryPageSize + 1);
    return _append(items);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (state.isLoading || current == null || current.isLoadingMore || !current.hasMore) return;
    final generation = _generation;
    state = AsyncData(AiNewsSearchResults(items: current.items, hasMore: current.hasMore, nextOffset: current.nextOffset, isLoadingMore: true));
    try {
      final items = await ref
          .read(aiNewsCacheDaoProvider)
          .searchAll(query, category: ref.read(aiNewsCategoryFilterProvider), filter: ref.read(aiNewsLibraryFilterProvider), limit: aiNewsLibraryPageSize + 1, offset: current.nextOffset);
      if (!ref.mounted || generation != _generation) return;
      state = AsyncData(_append(items, previous: current));
    } catch (error) {
      if (!ref.mounted || generation != _generation) return;
      state = AsyncData(AiNewsSearchResults(items: current.items, hasMore: current.hasMore, nextOffset: current.nextOffset, loadMoreError: error));
    }
  }

  AiNewsSearchResults _append(List<AiNewsItem> page, {AiNewsSearchResults? previous}) {
    final next = page.take(aiNewsLibraryPageSize).toList(growable: false);
    return AiNewsSearchResults(
      items: List.unmodifiable(
        {
          for (final item in [...?previous?.items, ...next]) item.id: item,
        }.values,
      ),
      hasMore: page.length > aiNewsLibraryPageSize,
      nextOffset: (previous?.nextOffset ?? 0) + next.length,
    );
  }
}
