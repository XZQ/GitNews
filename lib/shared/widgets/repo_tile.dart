import 'package:flutter/material.dart';

import '../../core/domain/repo_entity.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'data_provenance_badge.dart';
import 'star_trend_chart.dart';

/*
*仓库条目 — 全局统一的卡片式列表项。
*统一结构:[排名角标?][语言头像][名称/描述/指标] … [趋势或增量][尾部插槽?]
*设计约定:
*- 卡片 = 细边框 + md 圆角 + 悬停水波,列表间距由调用方用 SizedBox(sm) 控制
*- 右侧曲线只在 [RepoEntity.trend] 有真实数据时绘制;没有观测历史时
*  展示醒目的 Star 增量,不再用合成曲线充数(口径诚实,消除千篇一律)
*- `card: false` 保持无边框扁平行,供需要自行包裹容器的场景
*/
class RepoTile extends StatelessWidget {
  const RepoTile({
    required this.repo,
    this.showTrend = true,
    this.onTap,
    this.rank,
    this.trailing,
    this.card = true,
    super.key,
  });

  final RepoEntity repo;
  final bool showTrend;
  final VoidCallback? onTap;

  // 排名角标(1 起);null 不显示。
  final int? rank;

  // 尾部插槽:状态徽章、操作按钮等。
  final Widget? trailing;

  // 卡片样式开关。
  final bool card;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final accent = Color(repo.accentArgb);
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (rank != null) ...[_RankBadge(rank: rank!, accent: accent), const SizedBox(width: AppSpacing.sm)],
        Container(
          width: AppSpacing.xxl,
          height: AppSpacing.xxl,
          decoration: BoxDecoration(color: accent.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(AppRadius.sm)),
          alignment: Alignment.center,
          child: Text(repo.language.isNotEmpty ? repo.language[0] : '?', style: AppTypography.titleSmall.copyWith(color: accent)),
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
                style: AppTypography.titleSmall.copyWith(color: colors.onSurface),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                repo.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall.copyWith(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.xs2),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _Pill(text: repo.language, color: accent),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, size: 12, color: AppColors.starGold),
                      const SizedBox(width: AppSpacing.xxs),
                      Text(_shortNumber(repo.starCount), style: AppTypography.labelSmall.copyWith(color: colors.onSurface))
                    ],
                  ),
                  MetricBasisBadge(basis: repo.trendBasis)
                ],
              )
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        _TrendCell(repo: repo, showTrend: showTrend),
        if (trailing != null) ...[const SizedBox(width: AppSpacing.sm), trailing!]
      ],
    );

    if (!card) {
      return InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md), child: row));
    }

    final radius = BorderRadius.circular(AppRadius.md);
    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          decoration: BoxDecoration(borderRadius: radius, border: Border.all(color: colors.outlineVariant.withValues(alpha: isLight ? 0.45 : 0.6))),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
          child: row,
        ),
      ),
    );
  }
}

/*
*右侧趋势区:有真实观测曲线画 Sparkline + 增量;
*否则只展示增量数字,保持与曲线区等宽以对齐列表。
*/
class _TrendCell extends StatelessWidget {
  const _TrendCell({required this.repo, required this.showTrend});

  final RepoEntity repo;
  final bool showTrend;

  @override
  Widget build(BuildContext context) {
    final delta = repo.starDelta;
    final deltaColor = delta >= 0 ? AppColors.trendUp : AppColors.trendDown;
    final deltaText = Text('${delta >= 0 ? '+' : ''}${_shortNumber(delta.abs())}', style: AppTypography.titleSmall.copyWith(color: deltaColor, fontWeight: FontWeight.w700));
    final trend = repo.trend;
    if (!showTrend || trend == null || trend.isEmpty) {
      return SizedBox(
        width: 64,
        child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          deltaText,
          Icon(
            delta >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            size: 14,
            color: deltaColor,
          )
        ]),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        RepaintBoundary(
            child: Sparkline(
          values: trend,
          color: deltaColor,
          width: 64,
          height: 24,
        )),
        const SizedBox(height: AppSpacing.xxs),
        deltaText
      ],
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank, required this.accent});

  final int rank;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    // 前三名用主强调色突出,其余中性。
    final highlighted = rank <= 3;
    final color = highlighted ? colors.primary : colors.onSurfaceVariant;
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(color: color.withValues(alpha: highlighted ? 0.14 : 0.08), borderRadius: BorderRadius.circular(AppRadius.xs)),
      alignment: Alignment.center,
      child: Text('$rank', style: AppTypography.labelSmall.copyWith(color: color, fontWeight: FontWeight.w700)),
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
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.xs)),
      child: Text(text, style: AppTypography.labelSmall.copyWith(color: color, fontWeight: FontWeight.w600)),
    );
  }
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
