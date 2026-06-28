import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/gradient_hero_header.dart';
import '../../../../core/demo_data.dart';

class RepoDetailHeader extends StatelessWidget {
  const RepoDetailHeader({required this.repo, super.key});

  final DemoRepo repo;

  @override
  Widget build(BuildContext context) {
    return GradientHeroHeader(
      accent: Color(repo.color),
      title: repo.fullName,
      badges: [
        HeroBadge(label: repo.language, icon: Icons.bolt_rounded),
        const HeroBadge(label: '公开仓库', color: AppColors.info),
        const HeroBadge(label: '已加入监控', color: AppColors.success),
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
