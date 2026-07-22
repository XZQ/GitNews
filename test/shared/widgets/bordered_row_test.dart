import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/shared/widgets/bordered_row.dart';

/* 验证共享横向卡片在纵向滚动容器中的有限高度布局。 */
void main() {
  testWidgets('纵向滚动容器内可按最高子项等高布局', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 600,
            child: SingleChildScrollView(
              child: BorderedRow(
                children: [
                  SizedBox(key: Key('short'), height: 40),
                  SizedBox(key: Key('tall'), height: 80),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byKey(const Key('short'))).height, 80);
    expect(tester.getSize(find.byKey(const Key('tall'))).height, 80);
  });
}
