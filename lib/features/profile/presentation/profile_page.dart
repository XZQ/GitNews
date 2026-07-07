import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/breakpoint.dart';
import '../../../shared/widgets/responsive_layout.dart';
import 'widgets/profile_about_card.dart';
import 'widgets/profile_data_card.dart';
import 'widgets/profile_list_cards.dart';
import 'widgets/profile_master_detail.dart';
import 'widgets/profile_page_header.dart';
import 'widgets/profile_pro_card.dart';
import 'widgets/profile_settings_card.dart';
import 'widgets/profile_user_card.dart';

/* 设置页面: */
/* - 手机/平板:卡片纵向堆叠(单列)。 */
/* - 桌面:左侧设置项列表,右侧选中项的详情卡片。 */
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isCompact = Breakpoints.isCompact(context);
    return Scaffold(
      appBar: isCompact ? AppBar(title: Text(l10n.tr('profile.title'))) : null,
      body: ResponsiveLayout(
        compact: (_) => const _Mobile(),
        medium: (_) => const _Mobile(),
        expanded: (_) => const _Desktop(),
      ),
    );
  }
}

class _Mobile extends StatelessWidget {
  const _Mobile();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      children: const [
        ProfileUserCard(),
        SizedBox(height: AppSpacing.lg),
        ProfileProCard(),
        SizedBox(height: AppSpacing.lg),
        ProfileCollectListCard(),
        SizedBox(height: AppSpacing.lg),
        ProfileMonitorListCard(),
        SizedBox(height: AppSpacing.lg),
        ProfileDataCard(),
        SizedBox(height: AppSpacing.lg),
        ProfileSettingsCard(),
        SizedBox(height: AppSpacing.lg),
        ProfileAboutCard(),
      ],
    );
  }
}

class _Desktop extends StatelessWidget {
  const _Desktop();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProfilePageHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.xxxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ProfileUserCard(),
                SizedBox(height: AppSpacing.lg),
                ProfileMasterDetail(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
