import 'package:flutter/material.dart';

import '../../core/demo_data.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'star_trend_chart.dart';

/// 仓库列表项。
class RepoTile extends StatelessWidget {
  const RepoTile({
    required this.repo,
    this.showTrend = true,
    this.onTap,
    super.key,
  });

  final DemoRepo repo;
  final bool showTrend;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final trend =
        repo.trend ?? DemoData.generateStarTrend(repo.starCount - 5000, 5000);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Color(repo.color).withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                repo.language.isNotEmpty ? repo.language[0] : '?',
                style: AppTypography.titleSmall.copyWith(
                  color: Color(repo.color),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    repo.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.titleSmall.copyWith(
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    repo.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _Pill(text: repo.language, color: Color(repo.color)),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.star_rounded,
                        size: 12,
                        color: AppColors.starGold,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        _shortNumber(repo.starCount),
                        style: AppTypography.labelSmall.copyWith(
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '+${_shortNumber(repo.starDelta)}',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (showTrend) ...[
              const SizedBox(width: AppSpacing.md),
              Sparkline(
                values: trend,
                color: AppColors.success,
                width: 64,
                height: 28,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: AppTypography.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

String _shortNumber(int v) {
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
  return v.toString();
}
