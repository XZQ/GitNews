import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/skeleton.dart';

class TrendingSkeleton extends StatelessWidget {
  const TrendingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: const [
        Skeleton(height: 64),
        SizedBox(height: AppSpacing.lg),
        Skeleton(height: 280),
        SizedBox(height: AppSpacing.lg),
        Skeleton(height: 320),
      ],
    );
  }
}
