import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/utils/breakpoint.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../application/ai_news_library_providers.dart';
import '../application/ai_news_providers.dart';
import '../domain/ai_news_item.dart';
import 'widgets/ai_news_category_nav.dart';
import 'widgets/ai_news_item_list.dart';
import 'widgets/ai_news_list_skeleton.dart';
import 'widgets/ai_news_overview_header.dart';
import 'widgets/ai_news_page_header.dart';
import 'widgets/ai_news_search_results_body.dart';

/* 
*AI 动态页。
*数据源:`https://aihot.virxact.com/api/public/items`(精选流)。
*布局:顶部页头 + 分类导航条 + 分页列表(单页 10 条,触底自动加载)。
*/
class AiNewsPage extends ConsumerWidget {
  const AiNewsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = ref.watch(aiNewsCategoryFilterProvider);
    final isCompact = Breakpoints.isCompact(context);
    final categoryNav = AiNewsCategoryNav(selected: category, onSelected: (value) => ref.read(aiNewsCategoryFilterProvider.notifier).state = value);
    if (!isCompact) {
      return Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AiNewsPageHeader(),
            categoryNav,
            Expanded(child: _Body(category: category)),
          ],
        ),
      );
    }
    final content = NestedScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      headerSliverBuilder: (context, innerBoxIsScrolled) => [SliverToBoxAdapter(child: categoryNav)],
      body: _Body(category: category),
    );
    return Scaffold(
      appBar: const AiNewsCompactAppBar(),
      body: RefreshIndicator.adaptive(onRefresh: () => _refreshAiNews(ref), notificationPredicate: (notification) => notification.metrics.axis == Axis.vertical, child: content),
    );
  }

  /* 下拉刷新当前移动端视图,避免刷新与当前搜索/稍后读状态脱节。 */
  Future<void> _refreshAiNews(WidgetRef ref) async {
    if (ref.read(aiNewsReadLaterOnlyProvider)) {
      ref.invalidate(aiNewsReadLaterItemsProvider);
      await ref.read(aiNewsReadLaterItemsProvider.future);
      return;
    }
    final query = ref.read(aiNewsSearchQueryProvider).trim();
    if (query.isNotEmpty || ref.read(aiNewsLibraryFilterProvider).isActive) {
      ref.invalidate(aiNewsLibrarySearchProvider(query));
      await ref.read(aiNewsLibrarySearchProvider(query).future);
      return;
    }
    ref.invalidate(aiNewsItemsNotifierProvider);
    await ref.read(aiNewsItemsNotifierProvider.future);
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.category});

  final AiNewsCategory? category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(aiNewsSearchQueryProvider).trim();
    final readLaterOnly = ref.watch(aiNewsReadLaterOnlyProvider);
    final libraryFilter = ref.watch(aiNewsLibraryFilterProvider);

    // 稍后读视图:实体快照列表,静态展示(无远端分页)。
    if (readLaterOnly) {
      final async = ref.watch(aiNewsReadLaterItemsProvider);
      return async.when(
        data: (items) => items.isEmpty
            ? EmptyView(icon: Icons.bookmark_border_rounded, message: AppLocalizations.of(context).tr('ai_news.read_later_empty'))
            : AiNewsItemList(items: items, category: category, query: '', staticList: true, header: category == null ? const AiNewsOverviewHeader() : null),
        loading: () => const AiNewsListSkeleton(),
        error: (e, _) => ErrorView(error: e.asAppException(), onRetry: () => ref.invalidate(aiNewsReadLaterItemsProvider)),
      );
    }

    // 关键词搜索:查 SQLite 沉淀的全部历史条目(资讯库),而非内存分页。
    if (query.isNotEmpty || libraryFilter.isActive) {
      return AiNewsSearchResultsBody(query: query, category: category);
    }

    final async = ref.watch(aiNewsItemsNotifierProvider);
    return async.when(
      data: (items) => AiNewsItemList(items: items, category: category, query: '', header: category == null ? const AiNewsOverviewHeader() : null),
      loading: () => const AiNewsListSkeleton(),
      error: (e, _) => ErrorView(error: e.asAppException(), onRetry: () => ref.invalidate(aiNewsItemsNotifierProvider)),
    );
  }
}
