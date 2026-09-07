import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/i18n/app_localizations.dart';
import 'package:github_news/features/ai_news/application/ai_news_library_providers.dart';
import 'package:github_news/features/ai_news/domain/ai_news_library_filter.dart';
import 'package:github_news/features/ai_news/presentation/widgets/ai_news_library_filters_dialog.dart';

void main() {
  testWidgets('selected source remains valid while a different view loads its source list', (tester) async {
    final pending = Completer<List<String>>();
    final container = ProviderContainer(overrides: [aiNewsLibrarySourcesProvider.overrideWith((ref) => pending.future)]);
    addTearDown(container.dispose);
    container.read(aiNewsLibraryFilterProvider.notifier).state = const AiNewsLibraryFilter(source: 'Saved-only source');
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: AiNewsLibraryFiltersDialog())),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Saved-only source'), findsOneWidget);
    pending.complete(['Another source']);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Saved-only source'), findsOneWidget);
  });

  testWidgets('资讯库筛选的长来源名在 390px 宽度下不撑破弹窗', (tester) async {
    const longSource = 'A very long AI intelligence source name that must stay inside the mobile filter dialog';
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiNewsLibrarySourcesProvider.overrideWith((ref) async => [longSource]),
        ],
        child: MaterialApp(
          locale: const Locale('zh', 'CN'),
          localizationsDelegates: const [AppLocalizations.delegate, GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate, GlobalWidgetsLocalizations.delegate],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () => showDialog<void>(context: context, builder: (_) => const AiNewsLibraryFiltersDialog()),
                  child: const Text('打开筛选'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('打开筛选'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final dialogWidth = tester.getSize(find.byType(AlertDialog)).width;
    final fieldWidth = tester.getSize(find.byType(DropdownButtonFormField<String>)).width;
    expect(fieldWidth, lessThan(dialogWidth));

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text(longSource), findsOneWidget);
  });
}
