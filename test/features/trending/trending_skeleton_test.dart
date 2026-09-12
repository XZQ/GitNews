import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/theme/app_colors.dart';
import 'package:github_news/core/theme/app_theme.dart';
import 'package:github_news/features/trending/application/trending_providers.dart';
import 'package:github_news/features/trending/domain/trending_repository.dart';
import 'package:github_news/features/trending/presentation/hot_repos_page.dart';
import 'package:github_news/features/trending/widgets/trending_skeleton.dart';

void main() {
  testWidgets('hot repository secondary page loading fits a short compact window', (tester) async {
    tester.view.physicalSize = const Size(320, 260);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final pending = Completer<TrendingDigest>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [filteredTrendingDigestProvider.overrideWith((ref) => pending.future)],
        child: const MaterialApp(home: HotReposPage()),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(ListView), const Offset(0, -350));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  for (final dark in [false, true]) {
    for (final size in [const Size(320, 260), const Size(390, 480), const Size(980, 634.7)]) {
      testWidgets('loading fits and scrolls at $size in ${dark ? 'dark' : 'light'} theme', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? AppTheme.dark(AppColors.brand) : AppTheme.light(AppColors.brand),
            home: const Scaffold(body: TrendingSkeleton()),
          ),
        );
        expect(tester.takeException(), isNull);
        final state = tester.state<ScrollableState>(find.byType(Scrollable));
        expect(state.position.maxScrollExtent, greaterThan(0));
        await tester.drag(find.byType(TrendingSkeleton), const Offset(0, -700));
        await tester.pumpAndSettle();
        expect(state.position.pixels, greaterThan(0));
        expect(tester.takeException(), isNull);
      });
    }
  }
}
