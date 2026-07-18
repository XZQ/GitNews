import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/shared/widgets/star_trend_chart.dart';

void main() {
  testWidgets('窄屏和跨数量级曲线不会产生布局异常', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 480);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: EdgeInsets.all(16),
            child: StarTrendChart(
              series: [
                ChartSeries(
                  values: [42800, 42840, 42810, 42890, 42920, 42910, 42980],
                  color: Colors.teal,
                ),
                ChartSeries(
                  values: [0, 120, 260, 400, 520, 700, 820],
                  color: Colors.blue,
                ),
              ],
              height: 220,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(StarTrendChart), findsOneWidget);
  });

  testWidgets('空系列安全降级为空白图表区域', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StarTrendChart(
            series: [ChartSeries(values: [], color: Colors.teal)],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(StarTrendChart), findsOneWidget);
  });
}
