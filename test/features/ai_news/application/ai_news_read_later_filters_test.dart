import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/storage/local_database.dart';
import 'package:github_news/core/storage/storage_providers.dart';
import 'package:github_news/features/ai_news/application/ai_news_library_providers.dart';
import 'package:github_news/features/ai_news/application/ai_news_providers.dart';
import 'package:github_news/features/ai_news/domain/ai_news_item.dart';
import 'package:github_news/features/ai_news/domain/ai_news_library_filter.dart';

AiNewsItem _item(String id, {AiNewsCategory category = AiNewsCategory.aiModels, String source = 'Saved source', int day = 6}) => AiNewsItem(
  id: id,
  category: category,
  title: '人工智能模型 $id',
  titleEn: 'A model $id',
  summary: '发布详情',
  source: source,
  url: 'https://example.com/$id',
  permalink: '',
  publishedAt: DateTime.utc(2026, 9, day),
  score: 1,
  selected: true,
);

void main() {
  late LocalDatabase db;
  late ProviderContainer container;
  final now = DateTime.utc(2026, 9, 7);
  setUp(() async {
    db = await LocalDatabase.openInMemory();
    container = ProviderContainer(overrides: [appDatabaseProvider.overrideWithValue(db), clockProvider.overrideWithValue(() => now)]);
    container.listen(aiNewsReadLaterItemsProvider, (_, _) {});
  });
  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test('all controls filter durable snapshots after article cache is cleared', () async {
    final dao = container.read(aiNewsStateDaoProvider);
    for (final item in [_item('match'), _item('different', category: AiNewsCategory.paper), _item('old', day: 1), _item('end', day: 7), _item('other', source: 'Other')]) {
      await dao.toggleReadLater(item, now: now);
    }
    await container.read(aiNewsCacheDaoProvider).clear();
    container.read(aiNewsReadLaterOnlyProvider.notifier).state = true;
    container.read(aiNewsCategoryFilterProvider.notifier).state = AiNewsCategory.aiModels;
    container.read(aiNewsSearchQueryProvider.notifier).state = '模型 model';
    container.read(aiNewsLibraryFilterProvider.notifier).state = AiNewsLibraryFilter(
      source: 'Saved source',
      publishedAfter: DateTime.utc(2026, 9, 6),
      publishedBefore: now,
      read: AiNewsReadFilter.unread,
    );
    expect((await container.read(aiNewsReadLaterItemsProvider.future)).map((item) => item.id), ['match']);
    expect(await container.read(aiNewsLibrarySourcesProvider.future), ['Other', 'Saved source']);
    container.read(aiNewsCategoryFilterProvider.notifier).state = AiNewsCategory.paper;
    expect((await container.read(aiNewsReadLaterItemsProvider.future)).map((item) => item.id), ['different']);
    container.read(aiNewsSearchQueryProvider.notifier).state = "%' OR 1=1 --";
    expect(await container.read(aiNewsReadLaterItemsProvider.future), isEmpty);
  });

  test('marking read updates unread saved items and library searches immediately', () async {
    final item = _item('read');
    final controller = container.read(aiNewsLibraryControllerProvider);
    await controller.toggleReadLater(item);
    await container
        .read(aiNewsCacheDaoProvider)
        .upsertPage(
          category: null,
          cursor: null,
          digest: AiNewsDigest(items: [item], count: 1, hasNext: false),
          now: now,
        );
    container.read(aiNewsLibraryFilterProvider.notifier).state = const AiNewsLibraryFilter(read: AiNewsReadFilter.unread);
    container.listen(aiNewsLibrarySearchProvider('模型'), (_, _) {});
    expect(await container.read(aiNewsReadLaterItemsProvider.future), hasLength(1));
    expect((await container.read(aiNewsLibrarySearchProvider('模型').future)).items, hasLength(1));
    await controller.markRead(item);
    expect(await container.read(aiNewsReadLaterItemsProvider.future), isEmpty);
    expect((await container.read(aiNewsLibrarySearchProvider('模型').future)).items, isEmpty);
    container.read(aiNewsLibraryFilterProvider.notifier).state = const AiNewsLibraryFilter(read: AiNewsReadFilter.read);
    expect(await container.read(aiNewsReadLaterItemsProvider.future), hasLength(1));
    await controller.toggleReadLater(item);
    expect(await container.read(aiNewsReadLaterItemsProvider.future), isEmpty);
  });
}
