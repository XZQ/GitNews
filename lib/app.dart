import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/i18n/app_localizations.dart';
import 'core/preferences/locale_controller.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_controller.dart';
import 'core/theme/theme_preset_controller.dart';
import 'features/ai_news/application/ai_news_background_host.dart';
import 'shared/widgets/window_title_bar.dart';

// 仅供本地桌面验收构建使用,默认发布构建不启用。
const bool _uiAuditShortcutsEnabled = bool.fromEnvironment('UI_AUDIT_SHORTCUTS');

class GitHubNewsApp extends ConsumerWidget {
  const GitHubNewsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final mode = ref.watch(themeModeControllerProvider);
    final preset = ref.watch(themePresetControllerProvider);
    final locale = ref.watch(localeControllerProvider);
    return AiNewsBackgroundHost(
      child: Focus(
        autofocus: true,
        child: Shortcuts(
            // 桌面端全局快捷键:Ctrl/Cmd+数字切换一级 Tab。
            // 单独拦下 F5 / Ctrl+R 防止浏览器/Web 容器吃掉触发系统刷新。
            shortcuts: const {
              SingleActivator(LogicalKeyboardKey.digit1, control: true): _GoTabIntent(0),
              SingleActivator(LogicalKeyboardKey.digit2, control: true): _GoTabIntent(1),
              SingleActivator(LogicalKeyboardKey.digit3, control: true): _GoTabIntent(2),
              SingleActivator(LogicalKeyboardKey.digit4, control: true): _GoTabIntent(3),
              SingleActivator(LogicalKeyboardKey.digit5, control: true): _GoTabIntent(4),
              SingleActivator(LogicalKeyboardKey.digit6, control: true): _GoTabIntent(5),
              SingleActivator(LogicalKeyboardKey.digit7, control: true): _GoTabIntent(6),
              SingleActivator(LogicalKeyboardKey.digit8, control: true): _GoTabIntent(7),
              if (_uiAuditShortcutsEnabled) SingleActivator(LogicalKeyboardKey.numpad1): _GoTabIntent(0),
              if (_uiAuditShortcutsEnabled) SingleActivator(LogicalKeyboardKey.numpad2): _GoTabIntent(1),
              if (_uiAuditShortcutsEnabled) SingleActivator(LogicalKeyboardKey.numpad3): _GoTabIntent(2),
              if (_uiAuditShortcutsEnabled) SingleActivator(LogicalKeyboardKey.numpad4): _GoTabIntent(3),
              if (_uiAuditShortcutsEnabled) SingleActivator(LogicalKeyboardKey.numpad5): _GoTabIntent(4),
              if (_uiAuditShortcutsEnabled) SingleActivator(LogicalKeyboardKey.numpad6): _GoTabIntent(5),
              if (_uiAuditShortcutsEnabled) SingleActivator(LogicalKeyboardKey.numpad7): _GoTabIntent(6),
              if (_uiAuditShortcutsEnabled) SingleActivator(LogicalKeyboardKey.numpad8): _GoTabIntent(7),
              if (_uiAuditShortcutsEnabled) SingleActivator(LogicalKeyboardKey.numpadDivide): _GoPathIntent('/ai_news/detail/seed-001'),
              if (_uiAuditShortcutsEnabled) SingleActivator(LogicalKeyboardKey.numpadMultiply): _GoPathIntent('/ai_news/reminders'),
              if (_uiAuditShortcutsEnabled) SingleActivator(LogicalKeyboardKey.numpadSubtract): _GoPathIntent('/discover/detail/openai%2Fwhisper'),
              if (_uiAuditShortcutsEnabled) SingleActivator(LogicalKeyboardKey.numpadAdd): _GoPathIntent('/monitor/detail/anthropics%2Fclaude-code'),
              if (_uiAuditShortcutsEnabled) SingleActivator(LogicalKeyboardKey.numpadDecimal): _GoPathIntent('/monitor/alerts'),
              if (_uiAuditShortcutsEnabled) SingleActivator(LogicalKeyboardKey.f1): _GoPathIntent('/profile/collect'),
              if (_uiAuditShortcutsEnabled) SingleActivator(LogicalKeyboardKey.f2): _GoPathIntent('/profile/developers'),
              if (_uiAuditShortcutsEnabled) SingleActivator(LogicalKeyboardKey.f3): _GoPathIntent('/profile/monitor'),
              if (_uiAuditShortcutsEnabled) SingleActivator(LogicalKeyboardKey.f4): _GoPathIntent('/profile/rules'),
              if (_uiAuditShortcutsEnabled) SingleActivator(LogicalKeyboardKey.f6): _GoPathIntent('/profile/preferences'),
              if (_uiAuditShortcutsEnabled) SingleActivator(LogicalKeyboardKey.f7): _GoPathIntent('/profile/sources'),
              if (_uiAuditShortcutsEnabled) SingleActivator(LogicalKeyboardKey.f8): _GoPathIntent('/profile/server'),
              SingleActivator(LogicalKeyboardKey.keyR, control: true): _NoopIntent(),
              SingleActivator(LogicalKeyboardKey.f5): _NoopIntent()
            },
            child: Actions(
                actions: {
                  _GoTabIntent: CallbackAction<_GoTabIntent>(onInvoke: (intent) {
                    final i = intent.index;
                    if (i >= 0 && i < appTabs.length) {
                      router.go('/${appTabs[i].pathSegment}');
                    }
                    return null;
                  }),
                  _GoPathIntent: CallbackAction<_GoPathIntent>(onInvoke: (intent) {
                    router.go(intent.location);
                    return null;
                  }),
                  _NoopIntent: CallbackAction<_NoopIntent>(onInvoke: (_) => null)
                },
                child: MaterialApp.router(
                  title: 'Ai News',
                  debugShowCheckedModeBanner: false,
                  builder: (context, child) => DesktopWindowFrame(child: child ?? const SizedBox.shrink()),
                  theme: AppTheme.light(preset.seed),
                  darkTheme: AppTheme.dark(preset.seed),
                  themeMode: mode,
                  locale: locale,
                  routerConfig: router,
                  supportedLocales: AppLocalizations.supportedLocales,
                  localizationsDelegates: const [AppLocalizations.delegate, GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate, GlobalWidgetsLocalizations.delegate],
                ))),
      ),
    );
  }
}

class _GoTabIntent extends Intent {
  const _GoTabIntent(this.index);
  final int index;
}

class _GoPathIntent extends Intent {
  const _GoPathIntent(this.location);
  final String location;
}

class _NoopIntent extends Intent {
  const _NoopIntent();
}
