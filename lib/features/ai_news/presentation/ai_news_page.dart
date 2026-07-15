import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../application/ai_news_grouping.dart';
import '../application/ai_news_library_providers.dart';
import '../application/ai_news_providers.dart';
import '../domain/ai_news_item.dart';
import 'widgets/ai_news_category_nav.dart';
import 'widgets/ai_news_day_header.dart';
import 'widgets/ai_news_digest_card.dart';
import 'widgets/ai_news_list_skeleton.dart';
import 'widgets/ai_news_page_header.dart';
import 'widgets/ai_news_timeline_row.dart';

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
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AiNewsPageHeader(),
          AiNewsCategoryNav(selected: category, onSelected: (v) => ref.read(aiNewsCategoryFilterProvider.notifier).state = v),
          const AiNewsDigestCard(),
          Expanded(child: _Body(category: category))
        ],
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.category});

  final AiNewsCategory? category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(aiNewsSearchQueryProvider).trim();
    final readLaterOnly = ref.watch(aiNewsReadLaterOnlyProvider);

    // 稍后读视图:实体快照列表,静态展示(无远端分页)。
    if (readLaterOnly) {
      final async = ref.watch(aiNewsReadLaterItemsProvider);
      return async.when(
        data: (items) => items.isEmpty
            ? EmptyView(icon: Icons.bookmark_border_rounded, message: AppLocalizations.of(context).tr('ai_news.read_later_empty'))
            : _ItemList(
                items: items,
                category: category,
                query: '',
                staticList: true,
              ),
        loading: () => const AiNewsListSkeleton(),
        error: (e, _) => ErrorView(error: e.asAppException(), onRetry: () => ref.invalidate(aiNewsReadLaterItemsProvider)),
      );
    }

    // 关键词搜索:查 SQLite 沉淀的全部历史条目(资讯库),而非内存分页。
    if (query.isNotEmpty) {
      final async = ref.watch(aiNewsLibrarySearchProvider(query));
      return async.when(
        data: (items) => _ItemList(
          items: items,
          category: category,
          query: query,
          staticList: true,
        ),
        loading: () => const AiNewsListSkeleton(),
        error: (e, _) => ErrorView(error: e.asAppException(), onRetry: () => ref.invalidate(aiNewsLibrarySearchProvider(query))),
      );
    }

    final async = ref.watch(aiNewsItemsNotifierProvider);
    return async.when(
      data: (items) => _ItemList(items: items, category: category, query: ''),
      loading: () => const AiNewsListSkeleton(),
      error: (e, _) => ErrorView(error: e.asAppException(), onRetry: () => ref.invalidate(aiNewsItemsNotifierProvider)),
    );
  }
}

class _ItemList extends ConsumerStatefulWidget {
  const _ItemList({
    required this.items,
    required this.category,
    required this.query,
    this.staticList = false,
  });

  final List<AiNewsItem> items;
  final AiNewsCategory? category;
  final String query;

  // true = 静态数据集(搜索结果/稍后读),不做触底加载。
  final bool staticList;

  @override
  ConsumerState<_ItemList> createState() => _ItemListState();
}

/* 
*扁平化分组后的列表项(header / row)。
*/
class _FlatEntry {
  const _FlatEntry._({this.date, this.count, this.item});

  factory _FlatEntry.header(DateTime date, int count) => _FlatEntry._(date: date, count: count);
  factory _FlatEntry.item(AiNewsItem item) => _FlatEntry._(item: item);

  final DateTime? date;
  final int? count;
  final AiNewsItem? item;

  bool get isHeader => date != null;
}

class _ItemListState extends ConsumerState<_ItemList> {
  late final ScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (widget.staticList || widget.query.trim().isNotEmpty) {
      return;
    }
    if (!_controller.hasClients) {
      return;
    }
    final metrics = _controller.position;
    final distanceToBottom = metrics.maxScrollExtent - metrics.pixels;
    if (distanceToBottom < aiNewsLoadMoreScrollPixels) {
      ref.read(aiNewsItemsNotifierProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final query = widget.query.trim();
    if (widget.items.isEmpty) {
      return EmptyView(
        icon: Icons.article_outlined,
        message: query.isNotEmpty
            ? l10n.tr('ai_news.empty_search').replaceAll('{query}', query)
            : widget.category == null
                ? l10n.tr('ai_news.empty')
                : l10n.tr('ai_news.empty_category').replaceAll('{cat}', widget.category!.label),
      );
    }
    final hasMore = !widget.staticList && query.isEmpty && ref.read(aiNewsItemsNotifierProvider.notifier).hasMore;
    final groups = groupAiNewsByDay(widget.items);
    // 扁平化分组为 (header / row) 序列,SliverList 按 index lazy build。
    final flat = <_FlatEntry>[
      for (final g in groups) ...[_FlatEntry.header(g.key, g.value.length), for (final item in g.value) _FlatEntry.item(item)]
    ];
    return CustomScrollView(controller: _controller, slivers: [
      SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.xl,
            AppSpacing.xxxl,
          ),
          sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
            if (index < flat.length) {
              final e = flat[index];
              return RepaintBoundary(child: e.isHeader ? AiNewsDayHeader(date: e.date!, itemCount: e.count!) : AiNewsTimelineRow(item: e.item!, onTap: () => _openDetail(context, e.item!)));
            }
            return const AiNewsLoadMoreIndicator();
          }, childCount: flat.length + (hasMore ? 1 : 0))))
    ]);
  }

  void _openDetail(BuildContext context, AiNewsItem item) {
    context.go('/ai_news/detail/${Uri.encodeComponent(item.id)}');
  }
}
