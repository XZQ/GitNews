import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/utils/breakpoint.dart';
import '../../../shared/widgets/mobile_page_header.dart';
import '../../../shared/widgets/onboarding_dialog.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../widgets/devintel/devintel_desktop_page.dart';
import 'home_mobile_body.dart';
import 'home_tablet_body.dart';

/* 
*Home 三档分发:
*- **Expanded** (>= 1024):直接返回新的 [DevIntelDesktopPage],
*自带侧栏,跳过全局 [ResponsiveScaffold] 的 [AppSidebar](避免双重)。
*- **Medium** (600–1024):[HomeTabletBody]。
*- **Compact** (< 600):[HomeMobileBody]。
*首次启动时自动显示 Onboarding 引导对话框。
*/
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowOnboarding();
    });
  }

  void _maybeShowOnboarding() {
    final shouldShow = ref.read(shouldShowOnboardingProvider).valueOrNull;
    if (shouldShow == true && mounted) {
      showDialog(context: context, barrierDismissible: false, builder: (_) => const OnboardingDialog());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (Breakpoints.of(context) == FormFactor.expanded) {
      return const DevIntelDesktopPage();
    }
    final isCompact = Breakpoints.isCompact(context);
    return Scaffold(
        body: Column(children: [
      // 移动端统一页头(大标题 + 图标动作),替代默认 AppBar。
      if (isCompact) MobilePageHeader(title: AppLocalizations.of(context).tr('home.title')),
      Expanded(
        child: ResponsiveLayout(
          compact: (_) => const HomeMobileBody(),
          medium: (_) => const HomeTabletBody(),
          expanded: (_) => const SizedBox.shrink(),
        ),
      ),
    ]));
  }
}
