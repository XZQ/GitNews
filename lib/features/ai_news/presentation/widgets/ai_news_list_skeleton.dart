import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/skeleton.dart';

class AiNewsListSkeleton extends StatelessWidget {
  const AiNewsListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.xxxl,
      ),
      children: const [
        Skeleton(height: 24, width: 120),
        SizedBox(height: AppSpacing.md),
        Skeleton(height: 96),
        SizedBox(height: AppSpacing.md),
        Skeleton(height: 96),
        SizedBox(height: AppSpacing.md),
        Skeleton(height: 96),
        SizedBox(height: AppSpacing.md),
        Skeleton(height: 96)
      ],
    );
  }
}

class AiNewsLoadMoreIndicator extends StatelessWidget {
  const AiNewsLoadMoreIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Center(
            child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2.4),
        )));
  }
}
