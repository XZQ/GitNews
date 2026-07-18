import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
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

class AiNewsEndOfListFooter extends StatelessWidget {
  const AiNewsEndOfListFooter({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: label,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Row(
          children: [
            Expanded(child: Divider(color: colors.outlineVariant)),
            const SizedBox(width: AppSpacing.md),
            Icon(Icons.check_circle_outline_rounded, size: 18, color: colors.onSurfaceVariant),
            const SizedBox(width: AppSpacing.xs),
            Text(label, style: AppTypography.bodySmall.copyWith(color: colors.onSurfaceVariant)),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Divider(color: colors.outlineVariant)),
          ],
        ),
      ),
    );
  }
}
