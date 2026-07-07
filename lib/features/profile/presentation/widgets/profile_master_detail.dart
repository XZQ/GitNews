import 'package:flutter/material.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_card.dart';
import 'profile_about_card.dart';
import 'profile_data_card.dart';
import 'profile_detail_cards.dart';
import 'profile_pro_card.dart';
import 'profile_section.dart';
import 'profile_settings_card.dart';

/* 设置页桌面端 master-detail。 */
/*  */
/* 选中项是页面级 UI 状态,只在本页生命周期内有效, */
/* 不放进全局 Provider(CLAUDE.md §五.2)。 */
class ProfileMasterDetail extends StatefulWidget {
  const ProfileMasterDetail({super.key});

  @override
  State<ProfileMasterDetail> createState() => _ProfileMasterDetailState();
}

class _ProfileMasterDetailState extends State<ProfileMasterDetail> {
  ProfileSection _selected = ProfileSection.settings;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 45,
            child: _SectionList(
              selected: _selected,
              onSelected: (s) => setState(() => _selected = s),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            flex: 55,
            child: ProfileSectionDetail(section: _selected),
          ),
        ],
      ),
    );
  }
}

class _SectionList extends StatelessWidget {
  const _SectionList({required this.selected, required this.onSelected});

  final ProfileSection selected;
  final ValueChanged<ProfileSection> onSelected;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Text(
              AppLocalizations.of(context).tr('profile.master.title'),
              style: AppTypography.titleMedium,
            ),
          ),
          const Divider(height: 1),
          for (final s in ProfileSection.values)
            ProfileSectionListItem(
              section: s,
              selected: s == selected,
              onTap: () => onSelected(s),
            ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}

class ProfileSectionListItem extends StatelessWidget {
  const ProfileSectionListItem({
    required this.section,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final ProfileSection section;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = section.accentOf(context);
    final bg = selected ? accent.withValues(alpha: 0.12) : Colors.transparent;
    final fg = selected ? accent : colors.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      child: Container(
        color: bg,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Icon(section.icon, size: 18, color: fg),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                section.label(context),
                style: AppTypography.bodyMedium.copyWith(
                  color: selected ? colors.onSurface : null,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (selected) Icon(Icons.chevron_right, size: 16, color: accent),
          ],
        ),
      ),
    );
  }
}

class ProfileSectionDetail extends StatelessWidget {
  const ProfileSectionDetail({required this.section, super.key});

  final ProfileSection section;

  @override
  Widget build(BuildContext context) {
    final Widget body = switch (section) {
      ProfileSection.pro => const ProfileProCard(),
      ProfileSection.collect => const ProfileCollectDetailCard(),
      ProfileSection.developers => const ProfileDevelopersDetailCard(),
      ProfileSection.monitorTopics => const ProfileMonitorTopicsDetailCard(),
      ProfileSection.monitorRules => const ProfileMonitorRulesDetailCard(),
      ProfileSection.data => const ProfileDataCard(),
      ProfileSection.settings => const ProfileSettingsCard(),
      ProfileSection.about => const ProfileAboutCard(),
    };
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: KeyedSubtree(
        key: ValueKey<ProfileSection>(section),
        child: body,
      ),
    );
  }
}
