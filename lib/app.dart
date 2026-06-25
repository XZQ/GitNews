import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    return MaterialApp.router(
      title: 'GitHub News',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(preset.seed),
      darkTheme: AppTheme.dark(preset.seed),
      themeMode: mode,
      routerConfig: router,
      supportedLocales: const [Locale('zh', 'CN')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
    );
  }
}
