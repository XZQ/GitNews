import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/i18n/app_locale.dart';
import 'core/i18n/app_localizations.dart';
import 'core/i18n/locale_controller.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_controller.dart';
import 'core/theme/theme_preset_controller.dart';

class GitHubNewsApp extends ConsumerWidget {
  const GitHubNewsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final mode = ref.watch(themeModeControllerProvider);
    final preset = ref.watch(themePresetControllerProvider);
    final locale = ref.watch(materialLocaleProvider);
    return MaterialApp.router(
      title: ref.watch(appStringsProvider).t('app.title'),
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(preset.seed),
      darkTheme: AppTheme.dark(preset.seed),
      themeMode: mode,
      routerConfig: router,
      locale: locale,
      supportedLocales: AppLocale.values.map((e) => e.toLocale).toList(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      builder: (context, child) {
        return AppLocalizationsScope(
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
