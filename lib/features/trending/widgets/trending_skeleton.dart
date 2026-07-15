import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/skeleton.dart';

class TrendingSkeleton extends StatelessWidget {
  const TrendingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [Skeleton(height: 64), SizedBox(height: AppSpacing.lg), Skeleton(height: 280), SizedBox(height: AppSpacing.lg), Skeleton(height: 320)],
      ),
    );
  }
}
