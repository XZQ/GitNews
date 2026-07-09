import 'package:flutter/material.dart';

import '../../../../core/domain/contributor_entity.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/section_header.dart';

/* 贡献者卡片：展示项目核心开发者及其贡献数。 */
class ActivityContributorsCard extends StatelessWidget {
  const ActivityContributorsCard({super.key, required this.contributors});

  final List<ContributorEntity> contributors;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: l10n.tr('project.activity.developers'),
            subtitle: l10n.tr('project.activity.developers.subtitle'),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final c in contributors)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                radius: 16,
                backgroundColor: Color(
                  c.avatarAccentArgb,
                ).withValues(alpha: 0.16),
                child: Text(
                  c.login[0].toUpperCase(),
                  style: AppTypography.titleSmall.copyWith(
                    color: Color(c.avatarAccentArgb),
                  ),
                ),
              ),
              title: Text(c.login, style: AppTypography.titleSmall),
              subtitle: Text(
                l10n.tr('project.activity.contrib').replaceAll('{n}', c.contributions.toString()),
              ),
            ),
        ],
      ),
    );
  }
}
