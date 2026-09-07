import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/breakpoint.dart';
import '../../../../shared/widgets/empty_view.dart';
import '../../application/ai_news_event_clustering.dart';
import '../../application/ai_news_example_items.dart';
import '../../application/ai_news_feedback_providers.dart';
import '../../application/ai_news_providers.dart';
import '../../domain/ai_news_feedback.dart';
import '../../domain/ai_news_item.dart';
import 'ai_news_day_header.dart';
import 'ai_news_list_skeleton.dart';
import 'ai_news_timeline_row.dart';

class AiNewsItemList extends ConsumerStatefulWidget {
  const AiNewsItemList({
    required this.items,
    required this.category,
    required this.query,
    this.staticList = false,
    this.header,
    this.searchResults = false,
    this.pagingFooter,
    this.onLoadMore,
    super.key,
  });

  final List<AiNewsItem> items;
  final AiNewsCategory? category;
  final String query;

  // true = 静态数据集(搜索结果/稍后读),不做触底加载。
  final bool staticList;
  final bool searchResults;
  final Widget? pagingFooter;
  final VoidCallback? onLoadMore;

  // 列表顶部同向滚动的吸顶片(如 AI 日报卡片);为 null 时不渲染。
  final Widget? header;

  @override
  ConsumerState<AiNewsItemList> createState() => _AiNewsItemListState();
}

/*
*扁平化分组后的列表项(header / row)。
*/
class _FlatEntry {
  const _FlatEntry._({this.date, this.count, this.cluster, this.examples = false, this.isFirstInGroup = false, this.isLastInGroup = false});

  factory _FlatEntry.header(DateTime date, int count, {bool examples = false}) => _FlatEntry._(date: date, count: count, examples: examples);
  factory _FlatEntry.item(AiNewsEventCluster cluster, {required bool isFirstInGroup, required bool isLastInGroup}) =>
      _FlatEntry._(cluster: cluster, isFirstInGroup: isFirstInGroup, isLastInGroup: isLastInGroup);

  final DateTime? date;
  final int? count;
  final AiNewsEventCluster? cluster;
  final bool examples;

  // 当天分组内的首条,用于让列表卡收出顶部圆角。
  final bool isFirstInGroup;

  // 当天分组内的末条,用于让列表卡收出底部圆角并省略分隔线。
  final bool isLastInGroup;

  bool get isHeader => date != null;
}

class _AiNewsItemListState extends ConsumerState<AiNewsItemList> {
  // 聚类管线(排序 + O(n^2) 聚类 + 分组)只依赖 items 与兴趣画像;
  // 兴趣画像异步就绪、freshness 等无关重建不应重复整段计算,按引用相等缓存结果。
  List<_FlatEntry>? _flatCache;
  List<AiNewsItem>? _cachedItems;
  AiNewsInterestProfile? _cachedProfile;

  /* 监听内层列表剩余距离,不抢占 [NestedScrollView] 提供的滚动控制器。 */
  bool _onScrollNotification(ScrollNotification notification) {
    if (widget.onLoadMore != null && notification.metrics.axis == Axis.vertical && notification.metrics.extentAfter < aiNewsLoadMoreScrollPixels) {
      widget.onLoadMore!();
      return false;
    }
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

  List<_FlatEntry> _flatEntriesFor(AiNewsInterestProfile profile) {
    final items = widget.items;
    // Search hits retain database relevance order and remain individually accessible.
    if (widget.searchResults) {
      return [
        for (var i = 0; i < items.length; i++)
          _FlatEntry.item(
            AiNewsEventCluster(primary: items[i], items: [items[i]]),
            isFirstInGroup: i == 0,
            isLastInGroup: i == items.length - 1,
          ),
      ];
    }
    final cached = _flatCache;
    if (cached != null && identical(items, _cachedItems) && identical(profile, _cachedProfile)) {
      return cached;
    }
    final groups = _groupEventsByDay(clusterAndRankAiNewsEvents(items, profile));
    final flat = <_FlatEntry>[
      for (final g in groups) ...[
        _FlatEntry.header(g.key, g.value.length, examples: g.value.every((cluster) => isAiNewsExample(cluster.primary))),
        for (var i = 0; i < g.value.length; i++) _FlatEntry.item(g.value[i], isFirstInGroup: i == 0, isLastInGroup: i == g.value.length - 1),
      ],
    ];
    _flatCache = flat;
    _cachedItems = items;
    _cachedProfile = profile;
    return flat;
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
    final showPagingFooter = widget.pagingFooter != null || (!widget.staticList && query.isEmpty);
    final profile = ref.watch(aiNewsInterestProfileProvider).value ?? AiNewsInterestProfile.empty;
    final isCompact = Breakpoints.isCompact(context);
    final flat = _flatEntriesFor(profile);
    return NotificationListener<ScrollNotification>(
      onNotification: _onScrollNotification,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (widget.header != null) SliverToBoxAdapter(child: widget.header),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(AppSpacing.lg, isCompact ? AppSpacing.xs : AppSpacing.md, isCompact ? AppSpacing.lg : AppSpacing.xl, AppSpacing.xxxl),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                if (index < flat.length) {
                  final e = flat[index];
                  final cluster = e.cluster;
                  return RepaintBoundary(
                    child: e.isHeader
                        ? AiNewsDayHeader(date: e.date!, itemCount: e.count!, labelOverride: e.examples ? l10n.tr('ai_news.example') : null)
                        : AiNewsTimelineRow(
                            item: cluster!.primary,
                            eventSources: cluster.sources,
                            isFirstInGroup: e.isFirstInGroup,
                            isLastInGroup: e.isLastInGroup,
                            onTap: () => _openDetail(context, cluster.primary),
                          ),
                  );
                }
                return widget.pagingFooter ?? (hasMore ? const AiNewsLoadMoreIndicator() : AiNewsEndOfListFooter(label: l10n.tr('ai_news.no_more')));
              }, childCount: flat.length + (showPagingFooter ? 1 : 0)),
            ),
          ),
        ],
      ),
    );
  }

  List<MapEntry<DateTime, List<AiNewsEventCluster>>> _groupEventsByDay(List<AiNewsEventCluster> clusters) {
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
