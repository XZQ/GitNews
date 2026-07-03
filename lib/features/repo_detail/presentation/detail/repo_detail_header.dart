import 'package:flutter/material.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/gradient_hero_header.dart';
import '../../../../core/domain/repo_entity.dart';

class RepoDetailHeader extends StatelessWidget {
  const RepoDetailHeader({required this.repo, super.key});

  final RepoEntity repo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GradientHeroHeader(
      accent: Color(repo.accentArgb),
      title: repo.fullName,
      badges: [
        HeroBadge(label: repo.language, icon: Icons.bolt_rounded),
        HeroBadge(
          label: l10n.tr('repo_detail.badge.public'),
          color: AppColors.info,
        ),
        HeroBadge(
          label: l10n.tr('repo_detail.badge.monitored'),
          color: AppColors.success,
        ),
      ],
      trailing: Text(
        repo.description,
        style: AppTypography.bodyMedium.copyWith(
          color: Colors.white.withValues(alpha: 0.92),
        ),
      ),
    );
  }
}
