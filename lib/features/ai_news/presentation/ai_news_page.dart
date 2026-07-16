import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../application/ai_news_event_clustering.dart';
import '../application/ai_news_feedback_providers.dart';
import '../application/ai_news_library_providers.dart';
import '../application/ai_news_providers.dart';
import '../domain/ai_news_feedback.dart';
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
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          const SliverToBoxAdapter(child: AiNewsPageHeader()),
          SliverToBoxAdapter(
            child: AiNewsCategoryNav(selected: category, onSelected: (value) => ref.read(aiNewsCategoryFilterProvider.notifier).state = value),
          ),
        ],
        body: _Body(category: category),
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
    final libraryFilter = ref.watch(aiNewsLibraryFilterProvider);

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
                header: const AiNewsDigestCard(),
              ),
        loading: () => const AiNewsListSkeleton(),
        error: (e, _) => ErrorView(error: e.asAppException(), onRetry: () => ref.invalidate(aiNewsReadLaterItemsProvider)),
      );
    }

    // 关键词搜索:查 SQLite 沉淀的全部历史条目(资讯库),而非内存分页。
    if (query.isNotEmpty || libraryFilter.isActive) {
      final async = ref.watch(aiNewsLibrarySearchProvider(query));
      return async.when(
        data: (items) => _ItemList(
          items: items,
          category: category,
          query: query,
          staticList: true,
          header: const AiNewsDigestCard(),
        ),
        loading: () => const AiNewsListSkeleton(),
        error: (e, _) => ErrorView(error: e.asAppException(), onRetry: () => ref.invalidate(aiNewsLibrarySearchProvider(query))),
      );
    }

    final async = ref.watch(aiNewsItemsNotifierProvider);
    return async.when(
      data: (items) => _ItemList(
        items: items,
        category: category,
        query: '',
        header: const AiNewsDigestCard(),
      ),
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
    this.header,
  });

  final List<AiNewsItem> items;
  final AiNewsCategory? category;
  final String query;

  // true = 静态数据集(搜索结果/稍后读),不做触底加载。
  final bool staticList;

  // 列表顶部同向滚动的吸顶片(如 AI 日报卡片);为 null 时不渲染。
  final Widget? header;

  @override
  ConsumerState<_ItemList> createState() => _ItemListState();
}

/* 
*扁平化分组后的列表项(header / row)。
*/
class _FlatEntry {
  const _FlatEntry._({this.date, this.count, this.cluster});

  factory _FlatEntry.header(DateTime date, int count) => _FlatEntry._(date: date, count: count);
  factory _FlatEntry.item(AiNewsEventCluster cluster) => _FlatEntry._(cluster: cluster);

  final DateTime? date;
  final int? count;
  final AiNewsEventCluster? cluster;

  bool get isHeader => date != null;
}

class _ItemListState extends ConsumerState<_ItemList> {
  /* 监听内层列表剩余距离,不抢占 [NestedScrollView] 提供的滚动控制器。 */
  bool _onScrollNotification(ScrollNotification notification) {
    if (widget.staticList || widget.query.trim().isNotEmpty) {
      return false;
    }
    if (notification.metrics.axis != Axis.vertical) {
      return false;
    }
    if (notification.metrics.extentAfter < aiNewsLoadMoreScrollPixels) {
      ref.read(aiNewsItemsNotifierProvider.notifier).loadMore();
    }
    return false;
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
    final profile = ref.watch(aiNewsInterestProfileProvider).valueOrNull ?? AiNewsInterestProfile.empty;
    final ranked = rankAiNewsByInterest(widget.items, profile);
    final groups = _groupEventsByDay(clusterAiNewsEvents(ranked));
    // 扁平化分组为 (header / row) 序列,SliverList 按 index lazy build。
    final flat = <_FlatEntry>[
      for (final g in groups) ...[_FlatEntry.header(g.key, g.value.length), for (final item in g.value) _FlatEntry.item(item)]
    ];
    return NotificationListener<ScrollNotification>(
      onNotification: _onScrollNotification,
      child: CustomScrollView(
        slivers: [
          if (widget.header != null) SliverToBoxAdapter(child: widget.header),
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
                  final cluster = e.cluster;
                  return RepaintBoundary(
                    child: e.isHeader
                        ? AiNewsDayHeader(date: e.date!, itemCount: e.count!)
                        : AiNewsTimelineRow(
                            item: cluster!.primary,
                            eventSources: cluster.sources,
                            onTap: () => _openDetail(context, cluster.primary),
                          ),
                  );
                }
                return const AiNewsLoadMoreIndicator();
              }, childCount: flat.length + (hasMore ? 1 : 0)),
            ),
          ),
        ],
      ),
    );
  }

  List<MapEntry<DateTime, List<AiNewsEventCluster>>> _groupEventsByDay(
    List<AiNewsEventCluster> clusters,
  ) {
    final groups = <DateTime, List<AiNewsEventCluster>>{};
    for (final cluster in clusters) {
      final local = cluster.primary.publishedAt.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      groups.putIfAbsent(day, () => []).add(cluster);
    }
    final entries = groups.entries.toList()..sort((left, right) => right.key.compareTo(left.key));
    return entries;
  }

  void _openDetail(BuildContext context, AiNewsItem item) {
    context.go('/ai_news/detail/${Uri.encodeComponent(item.id)}');
  }
}
