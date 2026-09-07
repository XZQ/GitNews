import 'package:flutter/material.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/repo_growth_chart.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../domain/project_repository.dart';

class ProjectTrendOverview extends StatelessWidget {
  const ProjectTrendOverview({required this.digest, super.key});

  final ProjectDigest digest;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: l10n.tr('growth.title'), subtitle: l10n.tr('growth.subtitle')),
          const SizedBox(height: AppSpacing.md),
          RepoGrowthChart(repos: digest.repos),
        ],
      ),
    );
  }
}
