import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/domain/repo_entity.dart';
import 'package:github_news/core/errors/app_exception.dart';
import 'package:github_news/core/i18n/app_localizations.dart';
import 'package:github_news/shared/widgets/empty_view.dart';
import 'package:github_news/shared/widgets/error_view.dart';
import 'package:github_news/shared/widgets/repo_tile.dart';

/* 
*Golden 渲染对照。
*修改 shared widget 视觉时,跑 `flutter test --update-goldens` 重新生成基线。
*/
void main() {
  Future<void> pumpScene(
    WidgetTester tester,
    Widget child, {
    required Type finderType,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh', 'CN'),
        home: Scaffold(body: child),
      ),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 50));
    expect(find.byType(finderType, skipOffstage: false), findsOneWidget);
  }

  testWidgets('EmptyView golden', (tester) async {
    await pumpScene(
      tester,
      const EmptyView(icon: Icons.inbox_outlined, message: '暂无数据'),
      finderType: EmptyView,
    );
    await expectLater(
      find.byType(EmptyView),
      matchesGoldenFile('goldens/empty_view.png'),
    );
  });

  testWidgets('ErrorView network golden', (tester) async {
    await pumpScene(
      tester,
      const ErrorView(
        error: AppException(kind: AppExceptionKind.network),
      ),
      finderType: ErrorView,
    );
    await expectLater(
      find.byType(ErrorView),
      matchesGoldenFile('goldens/error_view_network.png'),
    );
  });

  testWidgets('RepoTile golden', (tester) async {
    await pumpScene(
      tester,
      const RepoTile(
        repo: RepoEntity(
          fullName: 'rust-lang/rust',
          description:
              'Empowering everyone to build reliable and efficient software.',
          language: 'Rust',
          starCount: 98000,
          starDelta: 320,
          forkCount: 12500,
          accentArgb: 0xFFCE412B,
        ),
      ),
      finderType: RepoTile,
    );
    await expectLater(
      find.byType(RepoTile),
      matchesGoldenFile('goldens/repo_tile.png'),
    );
  });
}
