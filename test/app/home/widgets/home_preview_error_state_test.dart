import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/app/home/widgets/devintel/home_trending_preview.dart';
import 'package:github_news/app/home/widgets/home_mobile_radar_overview.dart';
import 'package:github_news/core/i18n/app_localizations.dart';
import 'package:github_news/features/tech_hotspot/application/tech_hotspot_providers.dart';
import 'package:github_news/features/tech_hotspot/domain/tech_hotspot_models.dart';
import 'package:github_news/features/trending/application/trending_providers.dart';
import 'package:github_news/shared/widgets/error_view.dart';

const _radarDigest = TechHotspotDigest(
  languages: [],
  topics: [TechTopic(id: 'agent', name: 'Agent 框架', category: 'Agent', heat: 90, growth: 10, mentions: 100, relatedRepos: 20, summary: '信号')],
  heatTrend: [],
  hotTags: [],
);

Widget _wrap(Widget child, List<Override> overrides) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      locale: const Locale('zh', 'CN'),
      localizationsDelegates: const [AppLocalizations.delegate, GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate, GlobalWidgetsLocalizations.delegate],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

void main() {
  testWidgets('热榜预览失败时显示错误与重试,而不是空白', (tester) async {
    await tester.pumpWidget(_wrap(const HomeTrendingPreview(), [trendingDigestProvider.overrideWith((ref) async => throw StateError('offline'))]));
    await tester.pumpAndSettle();

    expect(find.text('加载失败'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);
  });

  testWidgets('移动雷达的话题趋势跨源失败时显示错误态而不是永久骨架', (tester) async {
    await tester.pumpWidget(
      _wrap(const HomeMobileRadarOverview(), [
        techHotspotDigestProvider.overrideWith((ref) async => _radarDigest),
        trendingHomeDigestProvider.overrideWith((ref) async => throw StateError('offline')),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ErrorView), findsOneWidget);
  });
}
