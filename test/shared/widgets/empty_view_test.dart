import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/shared/widgets/empty_view.dart';

void main() {
  group('EmptyView', () {
    testWidgets('renders icon and message without action', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyView(icon: Icons.inbox, message: '暂无数据'),
          ),
        ),
      );
      expect(find.byIcon(Icons.inbox), findsOneWidget);
      expect(find.text('暂无数据'), findsOneWidget);
      // 无 action 时不应出现 FilledButton / TextButton。
      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('renders action button when provided', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyView(
              icon: Icons.inbox,
              message: '暂无数据',
              action: FilledButton(
                onPressed: () => tapped++,
                child: const Text('刷新'),
              ),
            ),
          ),
        ),
      );
      final button = find.widgetWithText(FilledButton, '刷新');
      expect(button, findsOneWidget);
      await tester.tap(button);
      expect(tapped, 1);
    });
  });
}
