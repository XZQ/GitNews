import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/skeleton.dart';

/* 
*项目深度报告页统一骨架屏。
*/
class ProjectPageSkeleton extends StatelessWidget {
  const ProjectPageSkeleton({this.blocks = const [180, 240, 180], super.key});

  final List<double> blocks;

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl), children: [
      for (var i = 0; i < blocks.length; i++) ...[Skeleton(height: blocks[i]), if (i != blocks.length - 1) const SizedBox(height: AppSpacing.lg)]
    ]);
  }
}
