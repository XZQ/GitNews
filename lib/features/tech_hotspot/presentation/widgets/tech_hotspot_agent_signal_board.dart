import 'package:flutter/material.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/breakpoint.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/empty_view.dart';
import '../../domain/tech_hotspot_models.dart';

class TechHotspotAgentSignalBoard extends StatelessWidget {
  const TechHotspotAgentSignalBoard({
    required this.topics,
    this.compact = false,
    super.key,
  });

  final List<TechTopic> topics;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final formFactor = Breakpoints.of(context);
    final signals = topics
        .where(
          (topic) => topic.category == 'Agent' || topic.name.contains('AI Coding') || topic.name.contains('本地推理'),
        )
        .take(3)
        .toList(growable: false);

    return AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(
        children: [
          if (!compact) ...[
            Icon(Icons.device_hub_rounded, size: 16, color: colors.primary),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(child: Text(l10n.tr('tech_hotspot.agent_board.title'), style: AppTypography.titleSmall.copyWith(color: colors.onSurface, fontWeight: FontWeight.w700))),
          Text(l10n.tr('tech_hotspot.agent_board.source'), style: AppTypography.labelSmall.copyWith(color: colors.onSurfaceVariant, fontWeight: FontWeight.w600))
        ],
      ),
      if (!compact) ...[
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.tr('tech_hotspot.agent_board.subtitle'),
          style: AppTypography.bodySmall.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
      SizedBox(height: compact ? AppSpacing.sm : AppSpacing.lg),
      if (signals.isEmpty)
        EmptyView(icon: Icons.search_off_rounded, message: l10n.tr('tech_hotspot.empty.agent_signals'))
      else if (formFactor == FormFactor.expanded)
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (var i = 0; i < signals.length; i++) ...[if (i > 0) const SizedBox(width: AppSpacing.lg), Expanded(child: _AgentSignalItem(rank: i + 1, topic: signals[i], compact: compact))]
        ])
      else
        Column(children: [
          for (var i = 0; i < signals.length; i++) ...[
            if (i > 0) compact ? const Divider(height: 1) : const SizedBox(height: AppSpacing.md),
            _AgentSignalItem(rank: i + 1, topic: signals[i], compact: compact),
          ]
        ])
    ]));
  }
}

class _AgentSignalItem extends StatelessWidget {
  const _AgentSignalItem({
    required this.rank,
    required this.topic,
    required this.compact,
  });

  final int rank;
  final TechTopic topic;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final accent = switch (rank) { 1 => AppColors.danger, 2 => AppColors.brand, _ => AppColors.info };
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 0 : AppSpacing.md, vertical: compact ? AppSpacing.md : AppSpacing.md),
      decoration: BoxDecoration(
        color: compact ? Colors.transparent : colors.surfaceContainerHighest.withValues(alpha: isLight ? 0.6 : 0.42),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: compact ? null : Border.all(color: colors.outlineVariant.withValues(alpha: isLight ? 0.38 : 0.7), width: isLight ? 0.5 : 0.8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: accent.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(AppRadius.sm)),
            child: Text('$rank', style: AppTypography.titleSmall.copyWith(color: accent, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                        child: Text(
                      topic.name,
                      style: AppTypography.titleSmall.copyWith(color: colors.onSurface, fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )),
                    const SizedBox(width: AppSpacing.sm),
                    if (!compact) ...[
                      Icon(topic.growth >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded, size: 14, color: topic.growth >= 0 ? accent : AppColors.trendDown),
                      const SizedBox(width: AppSpacing.xxs),
                    ],
                    Text(
                      '${topic.growth > 0 ? '+' : ''}${topic.growth.toStringAsFixed(1)}%',
                      style: AppTypography.labelSmall.copyWith(
                        color: topic.growth >= 0 ? accent : AppColors.trendDown,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  topic.summary,
                  style: AppTypography.bodySmall.copyWith(color: colors.onSurfaceVariant, height: 1.45),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(Icons.local_fire_department_rounded, size: 13, color: colors.onSurfaceVariant),
                    const SizedBox(width: AppSpacing.xxs),
                    Text('${topic.heat}', style: AppTypography.labelSmall.copyWith(color: colors.onSurfaceVariant)),
                    const SizedBox(width: AppSpacing.md),
                    Icon(Icons.book_outlined, size: 13, color: colors.onSurfaceVariant),
                    const SizedBox(width: AppSpacing.xxs),
                    Text('${topic.relatedRepos}', style: AppTypography.labelSmall.copyWith(color: colors.onSurfaceVariant)),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
