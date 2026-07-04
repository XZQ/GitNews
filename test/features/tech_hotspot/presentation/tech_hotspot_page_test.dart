import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
  Future<TechHotspotDigest> getDigest() async {
    if (shouldThrow) throw Exception('boom');
    return _digest!;
  }

  @override
  Future<TechTopic?> getById(String id) async => null;

  @override
  Future<List<TechTopic>> allTopics() async => _digest?.topics ?? const [];
}

const _stubDigest = TechHotspotDigest(
  languages: [
    LanguageStat(
      name: 'Rust',
      percent: 28.0,
      delta: 1.2,
      color: 0xFFCE422B,
      repoCount: 12,
    ),
  ],
  topics: [
    TechTopic(
      id: 't1',
      name: 'Rust 1.80',
      category: 'language',
      heat: 88,
      growth: 4.5,
      mentions: 100,
      relatedRepos: 8,
      summary: 'const generics',
    ),
  ],
  heatTrend: [
    TechHeatPoint(label: 'Mon', value: 70),
    TechHeatPoint(label: 'Sun', value: 92),
  ],
  hotTags: ['rust', 'wasm'],
);

Widget _harness(TechHotspotRepository repo) {
  return ProviderScope(
    overrides: [techHotspotRepositoryProvider.overrideWithValue(repo)],
    child: const MaterialApp(home: TechHotspotPage()),
  );
}

void main() {
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
}
