import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/features/tech_hotspot/application/tech_hotspot_providers.dart';

void main() {
  test('should expose local tech hotspot digest when provider is read', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final digest = container.read(techHotspotDigestProvider);

    expect(digest.languages, isNotEmpty);
    expect(digest.topics, isNotEmpty);
    expect(digest.heatTrend, isNotEmpty);
    expect(digest.hotTags, isNotEmpty);
    expect(digest.topics.every((topic) => topic.heat >= 0), isTrue);
  });
}
