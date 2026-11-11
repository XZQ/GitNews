import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/i18n/app_localizations.dart';
import 'package:github_news/features/project/presentation/widgets/project_page_header.dart';
import 'package:github_news/features/trending/widgets/trending_page_header.dart';
import 'package:go_router/go_router.dart';

Widget _wrap(GoRouter router) {
  return ProviderScope(
    child: MaterialApp.router(
      locale: const Locale('zh', 'CN'),
      localizationsDelegates: const [AppLocalizations.delegate, GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate, GlobalWidgetsLocalizations.delegate],
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

GoRouter _router({required String initial, required Widget home, required Map<String, String> markers}) {
  return GoRouter(
    initialLocation: initial,
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => Scaffold(body: SingleChildScrollView(child: home)),
      ),
      for (final entry in markers.entries)
        GoRoute(
          path: entry.key,
          builder: (_, __) => Scaffold(body: Text(entry.value)),
        ),
    ],
  );
}

void main() {
  testWidgets('报告页菜单可进入四个已实现的二级页', (tester) async {
    final markers = {'/project/explore': '探索页', '/project/activity': '活动页', '/project/discover': '发现页', '/project/growth': '增长页'};
    final router = _router(initial: '/', home: const ProjectPageHeader(), markers: markers);
    await tester.pumpWidget(_wrap(router));
    await tester.pumpAndSettle();

    const entries = [('探索', '探索页'), ('活动速览', '活动页'), ('发现推荐', '发现页'), ('Star 增长趋势', '增长页')];
    for (final (label, marker) in entries) {
      await tester.tap(find.byIcon(Icons.more_horiz_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
      expect(find.text(marker), findsOneWidget, reason: '$label 应导航到 $marker');
      // 入口用 context.go 替换整栈,回到报告页继续验证下一个入口。
      router.go('/');
      await tester.pumpAndSettle();
    }
  });

  testWidgets('热榜页头可进入语言趋势二级页', (tester) async {
    await tester.pumpWidget(_wrap(_router(initial: '/', home: const TrendingPageHeader(), markers: {'/trending/language': '语言趋势页'})));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('语言趋势'));
    await tester.pumpAndSettle();

    expect(find.text('语言趋势页'), findsOneWidget);
  });
}
