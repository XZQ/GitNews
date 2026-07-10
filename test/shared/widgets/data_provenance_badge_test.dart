import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/domain/data_freshness.dart';
import 'package:github_news/core/domain/data_provenance.dart';
import 'package:github_news/shared/widgets/data_provenance_badge.dart';

void main() {
  testWidgets('DataProvenanceBadge shows compact label and tooltip', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DataProvenanceBadge(provenance: DataProvenance.estimated),
        ),
      ),
    );

    expect(find.text('Estimated'), findsOneWidget);

    await tester.longPress(find.byType(DataProvenanceBadge));
    await tester.pumpAndSettle();

    expect(find.textContaining('not complete history'), findsOneWidget);
  });

  testWidgets('freshness and metric badges expose separate meanings', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              DataFreshnessBadge(freshness: DataFreshness.freshCache),
              MetricBasisBadge(basis: MetricBasis.estimated),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Fresh cache'), findsOneWidget);
    expect(find.text('Estimated'), findsOneWidget);
  });
}
