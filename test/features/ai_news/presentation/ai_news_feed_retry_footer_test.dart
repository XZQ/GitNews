import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/features/ai_news/application/ai_news_feedback_providers.dart';
import 'package:github_news/features/ai_news/application/ai_news_library_providers.dart';
import 'package:github_news/features/ai_news/application/ai_news_providers.dart';
import 'package:github_news/features/ai_news/domain/ai_news_feedback.dart';
import 'package:github_news/features/ai_news/domain/ai_news_item.dart';
import 'package:github_news/features/ai_news/domain/ai_news_item_state.dart';
import 'package:github_news/features/ai_news/presentation/widgets/ai_news_item_list.dart';

/*
*以已载条目和一次可重试错误隔离列表页尾的交互。
*/
class _FailedPageNotifier extends AiNewsItemsNotifier {
  // 首屏条目不因页尾错误丢失。
  final AiNewsItem item = AiNewsItem(
    id: 'loaded',
    category: AiNewsCategory.aiModels,
    title: 'Already loaded article',
    titleEn: '',
    summary: '',
    source: 'Source',
    url: '',
    permalink: '',
    publishedAt: DateTime.utc(2026, 10, 12),
    score: 0,
    selected: true,
  );

  // 模拟重试成功后错误解除。
  bool failed = true;

  // 检查滚动不自行重试、按钮点击只提交一次。
  int retryCalls = 0;

  @override
  /* 返回已有内容，测试不依赖网络和 SQLite。 */
  Future<List<AiNewsItem>> build() async => [item];

  @override
  /* 失败页仍有后续内容，成功重试后到达末尾。 */
  bool get hasMore => failed;

  @override
  /* 给列表一个明确的分页错误，恢复后清除。 */
  Object? get loadMoreError => failed ? StateError('simulated offline') : null;

  @override
  /* 发布恢复后的同一批条目以触发页尾重建。 */
  Future<void> loadMore() async {
    retryCalls++;
    failed = false;
    state = AsyncData([item]);
  }
}

/*
*按真实页面的数据订阅方式重建列表，保留 notifier 页尾契约。
*/
class _ListHost extends ConsumerWidget {
  const _ListHost();

  @override
  /* 页面订阅列表状态并保留正常资讯流的分页入口。 */
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(aiNewsItemsNotifierProvider).value;
    return Scaffold(
      body: items == null ? const SizedBox.shrink() : AiNewsItemList(items: items, category: null, query: ''),
    );
  }
}

/* 失败时保留条目并提供按钮，成功后才展示真实列表末尾。 */
void main() {
  testWidgets('feed paging error offers explicit retry instead of end-of-list', (tester) async {
    final notifier = _FailedPageNotifier();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiNewsItemsNotifierProvider.overrideWith(() => notifier),
          aiNewsInterestProfileProvider.overrideWith((ref) async => AiNewsInterestProfile.empty),
          aiNewsItemStateProvider.overrideWith((ref, id) async => AiNewsItemState.none),
        ],
        child: const MaterialApp(home: _ListHost()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Already loaded article'), findsOneWidget);
    expect(find.text('No more data'), findsNothing);
    await tester.ensureVisible(find.text('Loading failed — retry'));
    await tester.pumpAndSettle();
    expect(notifier.retryCalls, 0);

    await tester.tap(find.text('Loading failed — retry'));
    await tester.pumpAndSettle();
    expect(notifier.retryCalls, 1);
    expect(find.text('Already loaded article'), findsOneWidget);
    expect(find.text('Loading failed — retry'), findsNothing);
    expect(find.text('No more data'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
