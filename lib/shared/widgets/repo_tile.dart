import 'package:flutter/material.dart';

import '../../core/demo_data.dart';
import '../../core/domain/repo_entity.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'data_provenance_badge.dart';
import 'star_trend_chart.dart';

/* 
*仓库列表项。
*/
class RepoTile extends StatelessWidget {
  const RepoTile({
    required this.repo,
    this.showTrend = true,
    this.onTap,
    super.key,
  });

  final RepoEntity repo;
  final bool showTrend;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = Color(repo.accentArgb);
    final trend = _resolveTrend(repo);
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
              width: AppSpacing.xxl,
              height: AppSpacing.xxl,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              alignment: Alignment.center,
              child: Text(
                repo.language.isNotEmpty ? repo.language[0] : '?',
                style: AppTypography.titleSmall.copyWith(color: accent),
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
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    repo.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs2),
                  Row(
                    children: [
                      _Pill(text: repo.language, color: accent),
                      const SizedBox(width: AppSpacing.sm),
                      Icon(
                        Icons.star_rounded,
                        size: 12,
                        color: colors.tertiary,
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      Text(
                        _shortNumber(repo.starCount),
                        style: AppTypography.labelSmall.copyWith(
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '+${_shortNumber(repo.starDelta)}',
                        style: AppTypography.labelSmall.copyWith(
                          color: colors.tertiary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      MetricBasisBadge(basis: repo.trendBasis),
                    ],
                  ),
                ],
              ),
            ),
            if (showTrend) ...[
              const SizedBox(width: AppSpacing.md),
              RepaintBoundary(
                child: Sparkline(
                  values: trend,
                  color: colors.tertiary,
                  width: 64,
                  height: 28,
                ),
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.xs),
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

// 模块级趋势记忆化缓存:避免滚动/筛选重建时为同一仓库重复生成曲线。
// 必须是可变 Map(putIfAbsent 会写入),故用 final 而非 const。
final Map<String, List<double>> _trendCache = <String, List<double>>{};

List<double> _resolveTrend(RepoEntity repo) {
  final provided = repo.trend;
  if (provided != null) {
    return provided;
  }
  final key = '${repo.fullName}:${repo.starCount}';
  return _trendCache.putIfAbsent(
    key,
    () => DemoData.generateStarTrend(repo.starCount - 5000, 5000),
  );
}

String _shortNumber(int v) {
  if (v >= 1000000) {
    return '${(v / 1000000).toStringAsFixed(1)}M';
  }
  if (v >= 1000) {
    return '${(v / 1000).toStringAsFixed(1)}k';
  }
  return v.toString();
}
