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
*- `dense: true` 为移动端紧凑密度:小头像、单行描述、收紧内边距
*/
class RepoTile extends StatelessWidget {
  const RepoTile({
    required this.repo,
    this.showTrend = true,
    this.onTap,
    this.rank,
    this.trailing,
    this.card = true,
    this.dense = false,
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

  // 紧凑密度(移动端)。
  final bool dense;

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
          width: dense ? AppSpacing.xl2 : AppSpacing.xxl,
          height: dense ? AppSpacing.xl2 : AppSpacing.xxl,
          decoration: BoxDecoration(color: accent.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(AppRadius.sm)),
          alignment: Alignment.center,
          child: Text(repo.language.isNotEmpty ? repo.language[0] : '?', style: (dense ? AppTypography.labelMedium : AppTypography.titleSmall).copyWith(color: accent)),
        ),
        SizedBox(width: dense ? AppSpacing.sm : AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                repo.fullName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.monoTitle.copyWith(color: colors.onSurface),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                repo.description,
                maxLines: dense ? 1 : 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall.copyWith(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.xs2),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _LanguageLabel(text: repo.language, color: accent),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, size: 12, color: AppColors.starGold),
                      const SizedBox(width: AppSpacing.xxs),
                      Text(_shortNumber(repo.starCount), style: AppTypography.monoMeta.copyWith(color: AppColors.starGold))
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
          padding: EdgeInsets.symmetric(horizontal: dense ? AppSpacing.sm2 : AppSpacing.md, vertical: dense ? AppSpacing.sm : AppSpacing.md),
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
    final deltaColor = delta > 0
        ? AppColors.trendUp
        : delta < 0
            ? AppColors.trendDown
            : Theme.of(context).colorScheme.onSurfaceVariant;
    final deltaText = Text(
      delta == 0 ? '—' : '${delta > 0 ? '+' : '-'}${_shortNumber(delta.abs())}',
      style: AppTypography.monoMetric.copyWith(color: deltaColor),
    );
    final trend = repo.trend;
    if (!showTrend || trend == null || trend.isEmpty) {
      // 无增量信息时不再渲染「+0 ↗」噪声,给一个安静的占位。
      if (delta == 0) {
        return SizedBox(
          width: 40,
          child: Text(
            '—',
            textAlign: TextAlign.right,
            style: AppTypography.monoMetric.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
          ),
        );
      }
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
      child: Text('$rank', style: AppTypography.monoMeta.copyWith(color: color, fontWeight: FontWeight.w700)),
    );
  }
}

/*
*语言标记 — 语言色圆点 + 等宽语言名。
*
*比填充药丸更安静:一行指标里同时出现语言、Star、口径徽章时,填充块会
*  和右侧趋势数字抢注意力,圆点方案把彩色压缩到 6px。
*/
class _LanguageLabel extends StatelessWidget {
  const _LanguageLabel({required this.text, required this.color});

  // 语言名;为空时整个标记不渲染。
  final String text;

  // 语言对应的品牌色,用于圆点填充。
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) {
      return const SizedBox.shrink();
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: AppSpacing.xs2,
          height: AppSpacing.xs2,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.xs2),
        Text(text, style: AppTypography.monoMeta.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
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
