import 'package:flutter/material.dart';

import '../../../core/utils/breakpoint.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../widgets/devintel/devintel_desktop_page.dart';
import 'home_legacy_desktop.dart';

/// Home 三档分发:
///
/// - **Expanded** (>= 1024):直接返回新的 [DevIntelDesktopPage],
///   自带侧栏,跳过全局 [ResponsiveScaffold] 的 [AppSidebar](避免双重)。
/// - **Medium** (600–1024):旧的 [HomeTabletBody](归档在
///   `home_legacy_desktop.dart`)。
/// - **Compact** (< 600):旧的 [HomeMobileBody](归档在
///   `home_legacy_desktop.dart`)。
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    if (Breakpoints.of(context) == FormFactor.expanded) {
      return const DevIntelDesktopPage();
    }
    return Scaffold(
      body: ResponsiveLayout(
        compact: (_) => const HomeMobileBody(),
        medium: (_) => const HomeTabletBody(),
        expanded: (_) => const SizedBox.shrink(),
      ),
    );
  }
}
