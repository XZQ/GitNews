import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/domain/data_freshness.dart';
import 'package:github_news/shared/widgets/data_provenance_badge.dart';

void main() {
  testWidgets('fresh cache stays quiet while estimated metrics remain explicit', (tester) async {
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

    expect(find.byType(Tooltip), findsOneWidget);
    expect(find.text('Estimated'), findsOneWidget);
  });
}
