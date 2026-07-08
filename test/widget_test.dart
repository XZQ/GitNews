import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:github_news/app.dart';
import 'package:github_news/core/di/providers.dart';

void main() {
  testWidgets('App boots to "设置" Scaffold', (tester) async {
    // appRouter 现同步读 startupTabControllerProvider → sharedPreferencesProvider,
    // 故测试需与 main() 一致地 override 该 provider。
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const GitHubNewsApp(),
      ),
    );
    // 渲染一帧即可,具体跳转由 go_router 接管。
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
