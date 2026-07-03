import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/preferences/link_open_mode_controller.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../application/ai_news_grouping.dart';
import '../application/ai_news_providers.dart';
import '../domain/ai_news_item.dart';
import 'widgets/ai_news_category_nav.dart';
import 'widgets/ai_news_day_header.dart';
import 'widgets/ai_news_list_skeleton.dart';
import 'widgets/ai_news_page_header.dart';
import 'widgets/ai_news_timeline_row.dart';

/// AI 动态页。
///
/// 数据源:`https://aihot.virxact.com/api/public/items`(精选流)。
/// 布局:顶部页头 + 分类导航条 + 分页列表(单页 10 条,触底自动加载)。
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
          AiNewsCategoryNav(
            selected: category,
            onSelected: (v) =>
                ref.read(aiNewsCategoryFilterProvider.notifier).state = v,
          ),
          Expanded(child: _Body(category: category)),
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
    final async = ref.watch(aiNewsItemsNotifierProvider);
    return async.when(
      data: (items) => _ItemList(items: items, category: category),
      loading: () => const AiNewsListSkeleton(),
      error: (e, _) => ErrorView(
        error: e.asAppException(),
        onRetry: () => ref.invalidate(aiNewsItemsNotifierProvider),
      ),
    );
  }
}

class _ItemList extends ConsumerStatefulWidget {
  const _ItemList({required this.items, required this.category});

  final List<AiNewsItem> items;
  final AiNewsCategory? category;

  @override
  ConsumerState<_ItemList> createState() => _ItemListState();
}

/// 扁平化分组后的列表项(header / row)。
class _FlatEntry {
  const _FlatEntry._({this.date, this.count, this.item});

  factory _FlatEntry.header(DateTime date, int count) =>
      _FlatEntry._(date: date, count: count);
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
    if (!_controller.hasClients) return;
    final metrics = _controller.position;
    final distanceToBottom = metrics.maxScrollExtent - metrics.pixels;
    if (distanceToBottom < aiNewsLoadMoreScrollPixels) {
      ref.read(aiNewsItemsNotifierProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (widget.items.isEmpty) {
      return EmptyView(
        icon: Icons.article_outlined,
        message: widget.category == null
            ? l10n.tr('ai_news.empty')
            : l10n
                .tr('ai_news.empty_category')
                .replaceAll('{cat}', widget.category!.label),
      );
    }
    final notifier = ref.read(aiNewsItemsNotifierProvider.notifier);
    final hasMore = notifier.hasMore;
    final groups = groupAiNewsByDay(widget.items);
    // 扁平化分组为 (header / row) 序列,SliverList 按 index lazy build。
    final flat = <_FlatEntry>[
      for (final g in groups) ...[
        _FlatEntry.header(g.key, g.value.length),
        for (final item in g.value) _FlatEntry.item(item),
      ],
    ];
    return CustomScrollView(
      controller: _controller,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.xl,
            AppSpacing.xxxl,
          ),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index < flat.length) {
                  final e = flat[index];
                  return e.isHeader
                      ? AiNewsDayHeader(date: e.date!, itemCount: e.count!)
                      : AiNewsTimelineRow(
                          item: e.item!,
                          onTap: () => _launch(
                            context,
                            e.item!.url,
                            e.item!.permalink,
                            title: e.item!.title,
                          ),
                        );
                }
                return const AiNewsLoadMoreIndicator();
              },
              childCount: flat.length + (hasMore ? 1 : 0),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _launch(
    BuildContext context,
    String primary,
    String fallback, {
    String title = '',
  }) async {
    final target = primary.isNotEmpty ? primary : fallback;
    if (target.isEmpty) return;
    final uri = Uri.tryParse(target);
    if (uri == null) return;
    final mode = ref.read(linkOpenModeControllerProvider);
    if (mode == LinkOpenMode.inApp) {
      context.go(
        Uri(
          path: '/webview',
          queryParameters: {
            'url': target,
            if (title.isNotEmpty) 'title': title,
          },
        ).toString(),
      );
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.tr('ai_news.open_failed'))),
      );
    }
  }
}
