import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_locale.dart';
import 'locale_controller.dart';
import 'strings.dart';

export 'app_locale.dart';
export 'locale_controller.dart';
export 'strings.dart';

/// 在 widget 树中提供 [AppStrings]。
class AppLocalizationsScope extends ConsumerWidget {
  const AppLocalizationsScope({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    return _InheritedAppStrings(
      strings: strings,
      child: child,
    );
  }
}

class _InheritedAppStrings extends InheritedWidget {
  const _InheritedAppStrings({
    required this.strings,
    required super.child,
  });

  final AppStrings strings;

  @override
  bool updateShouldNotify(_InheritedAppStrings oldWidget) =>
      oldWidget.strings.locale != strings.locale;
}

/// 便捷扩展:在任意 [BuildContext] 上取字符串。
extension AppStringsContext on BuildContext {
  AppStrings get t {
    final inherited =
        dependOnInheritedWidgetOfExactType<_InheritedAppStrings>();
    return inherited?.strings ?? const AppStrings(AppLocale.zh);
  }
}
