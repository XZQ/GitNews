import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/skeleton.dart';

class AiNewsDetailSkeleton extends StatelessWidget {
  const AiNewsDetailSkeleton({super.key});

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
        Skeleton(height: 220),
        SizedBox(height: AppSpacing.lg),
        Skeleton(height: 120),
      ],
    );
  }
}
