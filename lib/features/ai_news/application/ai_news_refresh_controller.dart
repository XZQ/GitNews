import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ai_news_library_providers.dart';
import 'ai_news_providers.dart';

final aiNewsRefreshControllerProvider = Provider<AiNewsRefreshController>(AiNewsRefreshController.new);

/// Shared by desktop refresh and mobile pull-to-refresh.
class AiNewsRefreshController {
  const AiNewsRefreshController(this._ref);
  final Ref _ref;

  Future<void> refresh() async {
    if (_ref.read(aiNewsReadLaterOnlyProvider)) {
      _ref.invalidate(aiNewsReadLaterItemsProvider);
      await _ref.read(aiNewsReadLaterItemsProvider.future);
      return;
    }
    final query = _ref.read(aiNewsSearchQueryProvider).trim();
    if (query.isNotEmpty || _ref.read(aiNewsLibraryFilterProvider).isActive) {
      _ref.invalidate(aiNewsLibrarySearchProvider(query));
      await _ref.read(aiNewsLibrarySearchProvider(query).future);
      return;
    }
    await _ref.read(aiNewsItemsNotifierProvider.notifier).refresh();
  }
}
