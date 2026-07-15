import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/domain/data_freshness.dart';
import 'package:github_news/features/tech_hotspot/application/tech_hotspot_providers.dart';
import 'package:github_news/features/tech_hotspot/domain/tech_hotspot_models.dart';
import 'package:github_news/features/tech_hotspot/domain/tech_hotspot_repository.dart';
import 'package:github_news/features/tech_hotspot/presentation/tech_hotspot_page.dart';
import 'package:github_news/shared/widgets/error_view.dart';

class _StubRepo implements TechHotspotRepository {
  _StubRepo(this._digest, {this.shouldThrow = false});

  final TechHotspotDigest? _digest;
  final bool shouldThrow;

  @override
  Future<DataResult<TechHotspotDigest>> getDigest() async {
    if (shouldThrow) {
      throw Exception('boom');
    }
    return DataResult(data: _digest!, freshness: DataFreshness.live);
  }

  @override
  Future<TechTopic?> getById(String id) async => null;

  @override
  Future<List<TechTopic>> allTopics() async => _digest?.topics ?? const [];
}

const _stubDigest = TechHotspotDigest(
  languages: [LanguageStat(name: 'Rust', percent: 28.0, delta: 1.2, color: 0xFFCE422B, repoCount: 12)],
  topics: [TechTopic(id: 't1', name: 'Rust 1.80', category: 'language', heat: 88, growth: 4.5, mentions: 100, relatedRepos: 8, summary: 'const generics')],
  heatTrend: [TechHeatPoint(label: 'Mon', value: 70), TechHeatPoint(label: 'Sun', value: 92)],
  hotTags: ['rust', 'wasm'],
);

Widget _harness(TechHotspotRepository repo) {
  return ProviderScope(overrides: [techHotspotRepositoryProvider.overrideWithValue(repo)], child: const MaterialApp(home: TechHotspotPage()));
}

void main() {
  Future<void> pumpAtSize(WidgetTester tester, Size size, Widget widget) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();
  }

  testWidgets('renders digest content after loading', (tester) async {
    final repo = _StubRepo(_stubDigest);
    await tester.pumpWidget(_harness(repo));
    await tester.pumpAndSettle();
    expect(find.text('Rust 1.80'), findsOneWidget);
    expect(find.text('# rust'), findsOneWidget);
  });

  testWidgets('tag tap should apply local search filter', (tester) async {
    final repo = _StubRepo(_stubDigest);
    await tester.pumpWidget(_harness(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('# rust'));
    await tester.pumpAndSettle();

    expect(find.text('Rust 1.80'), findsOneWidget);
    expect(find.text('# rust'), findsOneWidget);
  });

  testWidgets('renders ErrorView on repository failure', (tester) async {
    final repo = _StubRepo(null, shouldThrow: true);
    await tester.pumpWidget(_harness(repo));
    await tester.pumpAndSettle();
    expect(find.byType(ErrorView), findsOneWidget);
  });

  testWidgets('dense language panel should not overflow on desktop', (tester) async {
    final digest = TechHotspotDigest(languages: [
      for (var i = 0; i < 10; i++) LanguageStat(name: 'LanguageWithLongName$i', percent: 10, delta: i.isEven ? 1.2 : -0.8, color: 0xFF3178C6 + i, repoCount: 12 - i)
    ], topics: [
      for (var i = 0; i < 6; i++)
        TechTopic(
          id: 'topic-$i',
          name: 'AI Coding Signal $i',
          category: i.isEven ? 'Agent' : 'DevTools',
          heat: 70 + i,
          growth: (10 + i).toDouble(),
          mentions: 100 + i,
          relatedRepos: 20 + i,
          summary: 'A long but bounded summary for layout verification.',
        )
    ], heatTrend: [
      for (var i = 0; i < 7; i++) TechHeatPoint(label: 'D$i', value: (70 + i).toDouble())
    ], hotTags: [
      for (var i = 0; i < 12; i++) 'tag-$i'
    ]);

    await pumpAtSize(tester, const Size(1280, 720), _harness(_StubRepo(digest)));

    expect(tester.takeException(), isNull);
  });
}
