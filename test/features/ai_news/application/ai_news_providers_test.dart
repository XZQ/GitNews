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
}
