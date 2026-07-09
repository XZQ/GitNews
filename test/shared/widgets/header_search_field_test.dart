import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/shared/widgets/header_search_field.dart';

void main() {
  testWidgets('HeaderSearchField shows controlled value and clears it', (tester) async {
    var changed = 'unchanged';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HeaderSearchField(
            hintText: '搜索',
            value: 'codex',
            onChanged: (value) => changed = value,
          ),
        ),
      ),
    );

    expect(find.text('codex'), findsOneWidget);
    expect(find.byTooltip('Clear search'), findsOneWidget);

    await tester.tap(find.byTooltip('Clear search'));
    await tester.pump();

    expect(changed, '');
    expect(find.text('codex'), findsNothing);
  });
}
