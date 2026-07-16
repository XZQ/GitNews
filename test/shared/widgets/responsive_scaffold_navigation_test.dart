import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/i18n/app_localizations.dart';
import 'package:github_news/shared/widgets/responsive_scaffold.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('发现与今日二级页全屏且返回后恢复底部导航', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = _router();
    addTearDown(router.dispose);
    await tester.pumpWidget(_TestApp(router: router));
    await tester.pumpAndSettle();

    expect(find.text('发现一级页'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);

    await tester.tap(find.text('打开发现详情'));
    await tester.pumpAndSettle();

    expect(find.text('发现详情'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('发现一级页'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);

    router.go('/home');
    await tester.pumpAndSettle();
    await tester.tap(find.text('打开今日详情'));
    await tester.pumpAndSettle();

    expect(find.text('今日详情'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('今日一级页'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}

/* 创建覆盖八个桌面分支与五个移动目的地的最小路由。 */
GoRouter _router() {
  return GoRouter(
    initialLocation: '/discover',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => ResponsiveScaffold(navigationShell: shell),
        branches: [
          _branch(
            '/home',
            const _RootPage(title: '今日一级页', actionLabel: '打开今日详情', target: '/home/detail/repo'),
            routes: [GoRoute(path: 'detail/:id', builder: (_, __) => const _DetailPage(title: '今日详情'))],
          ),
          _branch('/ai_news', const _RootPage(title: 'AI 一级页')),
          _branch('/trending', const _RootPage(title: '热榜页')),
          _branch('/tech_hotspot', const _RootPage(title: '雷达页')),
          _branch(
            '/discover',
            const _RootPage(title: '发现一级页', actionLabel: '打开发现详情', target: '/discover/detail/repo'),
            routes: [GoRoute(path: 'detail/:id', builder: (_, __) => const _DetailPage(title: '发现详情'))],
          ),
          _branch('/monitor', const _RootPage(title: '监控一级页')),
          _branch('/project', const _RootPage(title: '报告页')),
          _branch('/profile', const _RootPage(title: '我的一级页')),
        ],
      ),
    ],
  );
}

/* 创建单个壳分支。 */
StatefulShellBranch _branch(String path, Widget root, {List<RouteBase> routes = const []}) {
  return StatefulShellBranch(
    routes: [GoRoute(path: path, builder: (_, __) => root, routes: routes)],
  );
}

/*
*测试应用壳,提供底部导航所需的本地化上下文。
*/
class _TestApp extends StatelessWidget {
  const _TestApp({required this.router});

  // 测试路由器。
  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp.router(
        locale: const Locale('zh', 'CN'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  }
}

/*
*测试用移动一级页面。
*/
class _RootPage extends StatelessWidget {
  const _RootPage({required this.title, this.actionLabel, this.target});

  // 页面标题。
  final String title;

  // 可选入口文案。
  final String? actionLabel;

  // 可选二级路由。
  final String? target;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: target == null
          ? Text(title)
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title),
                FilledButton(onPressed: () => context.go(target!), child: Text(actionLabel!)),
              ],
            ),
    );
  }
}

/*
*测试用全屏二级页面。
*/
class _DetailPage extends StatelessWidget {
  const _DetailPage({required this.title});

  // 页面标题。
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        title: Text(title),
      ),
    );
  }
}
