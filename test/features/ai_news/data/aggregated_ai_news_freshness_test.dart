import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/config/ai_news_sources_config.dart';
import 'package:github_news/core/domain/data_freshness.dart';
import 'package:github_news/features/ai_news/data/aggregated_ai_news_repository.dart';
import 'package:github_news/features/ai_news/data/ai_news_rss_client.dart';
import 'package:github_news/features/ai_news/domain/ai_news_item.dart';
import 'package:github_news/features/ai_news/domain/ai_news_repository.dart';
import 'package:mocktail/mocktail.dart';

class _Primary extends Mock implements AiNewsRepository {}

class _Rss extends Mock implements AiNewsRssClient {}

void main() {
  const source = AiNewsSourceConfig(id: 'rss', name: 'RSS', feedUrl: 'https://example.com/rss', categoryCode: 'industry');
  final now = DateTime.utc(2026, 9, 7);
  const digest = AiNewsDigest(items: [], count: 0, hasNext: false);

  for (final stale in [false, true]) {
    test('a ${stale ? 'stale' : 'failed'} source cannot be hidden by a live primary', () async {
      final primary = _Primary();
      final rss = _Rss();
      var successCount = 0;
      var failureCount = 0;
      when(() => primary.fetchItems(category: null, since: null, selectedOnly: true, force: false)).thenAnswer((_) async => DataResult(data: digest, freshness: DataFreshness.live, validatedAt: now));
      final stub = when(() => rss.fetchSource(source, now: now, force: false));
      if (stale) {
        stub.thenAnswer((_) async => DataResult(data: const [], freshness: DataFreshness.staleCache, validatedAt: now.subtract(const Duration(hours: 1))));
      } else {
        stub.thenThrow(StateError('unavailable'));
      }
      final repository = AggregatedAiNewsRepository(
        primary,
        rss,
        sources: const [source],
        clock: () => now,
        onSourceSuccess: (_, _) async {
          successCount++;
        },
        onSourceFailure: (_, _, _) async {
          failureCount++;
        },
      );
      final result = await repository.fetchItems();
      expect(result.freshness, DataFreshness.staleCache);
      expect(successCount, 0);
      expect(failureCount, 1);
    });
  }

  test('TTL hits preserve the oldest validation time and do not report another source success', () async {
    final primary = _Primary();
    final rss = _Rss();
    final original = now.subtract(const Duration(minutes: 3));
    var successes = 0;
    when(() => primary.fetchItems(category: null, since: null, selectedOnly: true, force: false)).thenAnswer((_) async => DataResult(data: digest, freshness: DataFreshness.live, validatedAt: now));
    when(() => rss.fetchSource(source, now: now, force: false)).thenAnswer((_) async => DataResult(data: const [], freshness: DataFreshness.freshCache, validatedAt: original));
    final repository = AggregatedAiNewsRepository(
      primary,
      rss,
      sources: const [source],
      clock: () => now,
      onSourceSuccess: (_, _) async {
        successes++;
      },
    );
    expect((await repository.fetchItems()).validatedAt, original);
    expect(successes, 0);
  });
}
