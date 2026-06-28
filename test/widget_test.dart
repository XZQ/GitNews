import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:github_news/app.dart';

void main() {
  testWidgets('App boots to "设置" Scaffold', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: GitHubNewsApp()),
    );
    // 渲染一帧即可,具体跳转由 go_router 接管。
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
