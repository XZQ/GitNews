import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/domain/data_freshness.dart';
import 'package:github_news/core/domain/repo_entity.dart';
import 'package:github_news/shared/widgets/repo_growth_chart.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('sparse dates and negative growth render in narrow $brightness chart', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: brightness),
          home: Scaffold(
            body: SizedBox(
              width: 320,
              child: RepoGrowthChart(
                now: DateTime.utc(2026, 7, 10),
                repos: [
                  RepoEntity(
                    fullName: 'test/repo',
                    description: '',
                    language: 'Dart',
                    starCount: 120,
                    starDelta: 20,
                    forkCount: 0,
                    accentArgb: 0,
                    trendBasis: MetricBasis.observed,
                    trend: const [100, 95, 120],
                    trendDates: [DateTime.utc(2026, 7, 1), DateTime.utc(2026, 7, 3), DateTime.utc(2026, 7, 10)],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final data = tester.widget<LineChart>(find.byType(LineChart)).data;
      expect(data.lineBarsData, hasLength(1));
      expect(data.lineBarsData.single.spots.map((spot) => spot.x), [0, 2, 9]);
      expect(data.lineBarsData.single.spots.map((spot) => spot.y), [0, -5, 20]);
      expect(data.minY, lessThan(0));
      expect(data.maxX, 9);
      expect(tester.takeException(), isNull);
      if (Platform.isWindows) {
        await expectLater(find.byType(RepoGrowthChart), matchesGoldenFile('goldens/repo_growth_${brightness.name}.png'));
      }
    });
  }

  testWidgets('missing history shows an empty state without a fabricated chart', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: RepoGrowthChart(repos: [])),
      ),
    );
    expect(find.byType(LineChart), findsNothing);
    expect(find.byType(Text), findsOneWidget);
  });
}
