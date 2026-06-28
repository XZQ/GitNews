import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/features/ai_news/application/ai_news_providers.dart';
import 'package:github_news/features/ai_news/domain/ai_news_item.dart';

void main() {
  test('should expose local AI news digest when provider is read', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final digest = container.read(aiNewsDigestProvider);

    expect(digest.items, isNotEmpty);
    expect(digest.items.where((e) => e.isHero), isNotEmpty);
    expect(digest.hotTopics, isNotEmpty);
    expect(digest.topCompanies, isNotEmpty);
    expect(digest.items.first.category, isA<AiNewsCategory>());
  });

  group('aiNewsFilteredItemsProvider', () {
    test(
      'should return all items when category filter is null',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final digest = container.read(aiNewsDigestProvider);
        final filtered = container.read(aiNewsFilteredItemsProvider);

        expect(filtered.length, digest.items.length);
      },
    );

    test(
      'should narrow items to the selected category',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final digest = container.read(aiNewsDigestProvider);
        final firstCategory = digest.items.first.category;

        container.read(aiNewsCategoryFilterProvider.notifier).state =
            firstCategory;
        final filtered = container.read(aiNewsFilteredItemsProvider);

        expect(filtered, isNotEmpty);
        for (final item in filtered) {
          expect(item.category, firstCategory);
        }
      },
    );

    test('should default window to 24h', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(aiNewsWindowFilterProvider), '24h');
    });
  });
}
