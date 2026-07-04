import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/breakpoint.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/skeleton.dart';
import '../application/tech_hotspot_providers.dart';
import '../domain/tech_hotspot_models.dart';
import 'widgets/tech_hotspot_heat_chart.dart';
import 'widgets/tech_hotspot_language_panel.dart';
import 'widgets/tech_hotspot_page_header.dart';
import 'widgets/tech_hotspot_topic_card.dart';

/// AI 雷达页(桌面 / Expanded)。
///
/// 结构:
/// - 顶部条 [TechHotspotPageHeader]
/// - 行 1:雷达标签云
/// - 行 2:Agent 榜观察
/// - 行 2:热度曲线(8) + 语言占比(4)
/// - 行 3:主题网格(2 列)
class TechHotspotPage extends ConsumerWidget {
  const TechHotspotPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(filteredTechHotspotDigestProvider);
    return Scaffold(
      body: state.when(
        data: (digest) => _Body(digest: digest),
        loading: () => const _TechHotspotSkeleton(),
        error: (error, stack) => ErrorView(
          error: error.asAppException(stack),
          onRetry: () => ref.invalidate(techHotspotDigestProvider),
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.digest});

  final TechHotspotDigest digest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCompact = Breakpoints.of(context) == FormFactor.compact;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TechHotspotPageHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              isCompact ? AppSpacing.lg : AppSpacing.xl,
              AppSpacing.lg,
              isCompact ? AppSpacing.lg : AppSpacing.xl,
              AppSpacing.xxxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TagsCloud(
                  tags: digest.hotTags,
                  onTagSelected: (tag) => ref
                      .read(techHotspotSearchQueryProvider.notifier)
                      .state = tag,
                ),
                const SizedBox(height: AppSpacing.lg),
                _AgentSignalBoard(topics: digest.topics),
                const SizedBox(height: AppSpacing.lg),
                _TopRow(digest: digest),
                const SizedBox(height: AppSpacing.lg),
                _TopicGrid(topics: digest.topics),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AgentSignalBoard extends StatelessWidget {
  const _AgentSignalBoard({required this.topics});

  final List<TechTopic> topics;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final formFactor = Breakpoints.of(context);
    final signals = topics
        .where(
          (topic) =>
              topic.category == 'Agent' ||
              topic.name.contains('AI Coding') ||
              topic.name.contains('本地推理'),
        )
        .take(3)
        .toList(growable: false);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.device_hub_rounded, size: 16, color: colors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.tr('tech_hotspot.agent_board.title'),
                  style: AppTypography.titleSmall.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                l10n.tr('tech_hotspot.agent_board.source'),
                style: AppTypography.labelSmall.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.tr('tech_hotspot.agent_board.subtitle'),
            style: AppTypography.bodySmall.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (signals.isEmpty)
            const EmptyView(
              icon: Icons.search_off_rounded,
              message: '没有匹配的 Agent 信号',
            )
          else if (formFactor == FormFactor.expanded)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < signals.length; i++) ...[
                  if (i > 0) const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: _AgentSignalItem(
                      rank: i + 1,
                      topic: signals[i],
                    ),
                  ),
                ],
              ],
            )
          else
            Column(
              children: [
                for (var i = 0; i < signals.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppSpacing.md),
                  _AgentSignalItem(rank: i + 1, topic: signals[i]),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _AgentSignalItem extends StatelessWidget {
  const _AgentSignalItem({required this.rank, required this.topic});

  final int rank;
  final TechTopic topic;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final accent = switch (rank) {
      1 => AppColors.danger,
      2 => AppColors.brand,
      _ => AppColors.info,
    };
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(
          alpha: isLight ? 0.6 : 0.42,
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: isLight ? 0.38 : 0.7),
          width: isLight ? 0.5 : 0.8,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              '$rank',
              style: AppTypography.titleSmall.copyWith(
                color: accent,
                fontWeight: FontWeight.w800,
              ),
            ),
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
                        style: AppTypography.titleSmall.copyWith(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Icon(Icons.trending_up_rounded, size: 14, color: accent),
                    const SizedBox(width: AppSpacing.xxs),
                    Text(
                      '+${topic.growth.toStringAsFixed(1)}%',
                      style: AppTypography.labelSmall.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  topic.summary,
                  style: AppTypography.bodySmall.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.45,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(
                      Icons.local_fire_department_rounded,
                      size: 13,
                      color: colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSpacing.xxs),
                    Text(
                      '${topic.heat}',
                      style: AppTypography.labelSmall.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Icon(
                      Icons.book_outlined,
                      size: 13,
                      color: colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSpacing.xxs),
                    Text(
                      '${topic.relatedRepos}',
                      style: AppTypography.labelSmall.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopRow extends StatelessWidget {
  const _TopRow({required this.digest});

  final TechHotspotDigest digest;

  @override
  Widget build(BuildContext context) {
    final formFactor = Breakpoints.of(context);
    if (formFactor == FormFactor.expanded) {
      return SizedBox(
        height: 360,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 8,
              child: TechHotspotHeatChart(values: digest.heatTrend),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              flex: 4,
              child: TechHotspotLanguagePanel(languages: digest.languages),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 260,
          child: TechHotspotHeatChart(values: digest.heatTrend),
        ),
        const SizedBox(height: AppSpacing.lg),
        TechHotspotLanguagePanel(languages: digest.languages),
      ],
    );
  }
}

class _TopicGrid extends StatelessWidget {
  const _TopicGrid({required this.topics});

  final List<TechTopic> topics;

  @override
  Widget build(BuildContext context) {
    if (topics.isEmpty) {
      return const EmptyView(
        icon: Icons.search_off_rounded,
        message: '没有匹配的雷达主题',
      );
    }

    final formFactor = Breakpoints.of(context);
    final crossAxisCount = formFactor == FormFactor.expanded ? 2 : 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < topics.length; i += crossAxisCount)
          Padding(
            padding: EdgeInsets.only(
              bottom: i + crossAxisCount < topics.length ? AppSpacing.lg : 0,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var j = 0; j < crossAxisCount; j++) ...[
                  if (j > 0) const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: i + j < topics.length
                        ? TechHotspotTopicCard(
                            topic: topics[i + j],
                            onTap: () => context.go(
                              '/tech_hotspot/detail/${topics[i + j].id}',
                            ),
                          )
                        : const SizedBox(),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _TagsCloud extends StatelessWidget {
  const _TagsCloud({required this.tags, required this.onTagSelected});

  final List<String> tags;
  final ValueChanged<String> onTagSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.tag_rounded, size: 16, color: colors.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                l10n.tr('tech_hotspot.tag_cloud'),
                style: AppTypography.titleSmall.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (tags.isEmpty)
            const EmptyView(
              icon: Icons.sell_outlined,
              message: '没有匹配的雷达标签',
            )
          else
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final tag in tags)
                  _Tag(label: tag, onSelected: () => onTagSelected(tag)),
              ],
            ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.onSelected});

  final String label;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onSelected,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(
            '# $label',
            style: AppTypography.labelMedium.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _TechHotspotSkeleton extends StatelessWidget {
  const _TechHotspotSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xxxl,
      ),
      children: const [
        Skeleton(height: 92),
        SizedBox(height: AppSpacing.lg),
        Skeleton(height: 280),
        SizedBox(height: AppSpacing.lg),
        Skeleton(height: 320),
      ],
    );
  }
}
