import 'package:flutter/material.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../domain/entities.dart';

class RepoDetailContributors extends StatelessWidget {
  const RepoDetailContributors({required this.contributors, super.key});

  final List<ContributorEntity> contributors;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: l10n.tr('repo_detail.contributors_active'),
            subtitle: l10n.tr('repo_detail.contributors_active.subtitle'),
          ),
          const SizedBox(height: AppSpacing.md),
          Column(
            children: [
              for (final c in contributors) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 18,
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
                    l10n.tr('repo_detail.contrib.this_week').replaceAll('{n}', c.contributions.toString()),
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                ),
                const SizedBox(height: AppSpacing.xs),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
