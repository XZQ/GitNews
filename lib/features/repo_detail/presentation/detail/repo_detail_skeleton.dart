import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/skeleton.dart';

class RepoDetailSkeleton extends StatelessWidget {
  const RepoDetailSkeleton({super.key});

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
        Skeleton(height: 180),
        SizedBox(height: AppSpacing.lg),
        Skeleton(height: 92),
        SizedBox(height: AppSpacing.lg),
        Skeleton(height: 300),
        SizedBox(height: AppSpacing.lg),
        Skeleton(height: 260)
      ],
    );
  }
}
