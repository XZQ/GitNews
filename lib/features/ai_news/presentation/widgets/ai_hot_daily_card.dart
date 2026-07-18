import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/domain/data_freshness.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/data_provenance_badge.dart';
import '../../application/ai_news_providers.dart';
import '../../domain/ai_hot_daily.dart';

/*
*AI 页顶部的 AI HOT 官方日报卡。
*默认无 Key 可用,与下方可选的本地 LLM“我的日报”分离。
*/
class AiHotDailyCard extends ConsumerWidget {
  const AiHotDailyCard({super.key});

  @override
  /* 构建最新日报的 loading/data/error/empty 状态。 */
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(aiHotLatestDailyProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.xl, 0),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: state.when(
          loading: () => _StatusRow(
            icon: const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)),
            label: l10n.tr('ai_news.official_daily.loading'),
          ),
          error: (_, __) => _StatusRow(
            icon: Icon(Icons.cloud_off_rounded, color: Theme.of(context).colorScheme.error),
            label: l10n.tr('ai_news.official_daily.failed'),
            action: TextButton(
              onPressed: () => ref.invalidate(aiHotLatestDailyProvider),
              child: Text(l10n.tr('common.retry')),
            ),
          ),
          data: (result) => _DailyContent(report: result.data, freshness: result.freshness),
        ),
      ),
    );
  }
}

class _DailyContent extends ConsumerWidget {
  const _DailyContent({required this.report, required this.freshness});

  // 最新官方日报。
  final AiHotDailyReport report;

  // 当前响应新鲜度。
  final DataFreshness freshness;

  @override
  /* 构建日报摘要与详情入口。 */
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final headline = _headline(report);
    final summary = _summary(report);
    final version = ref.watch(aiHotVersionProvider).valueOrNull?.data.apiVersion;
    if (headline.isEmpty) {
      return _StatusRow(
        icon: const Icon(Icons.auto_stories_outlined),
        label: l10n.tr('ai_news.official_daily.empty'),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_stories_rounded, size: 20, color: AppColors.brand),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.tr('ai_news.official_daily.title'), style: AppTypography.titleMedium.copyWith(color: colors.onSurface)),
                  Text(l10n.tr('ai_news.official_daily.subtitle'), style: AppTypography.bodySmall.copyWith(color: colors.onSurfaceVariant)),
                ],
              ),
            ),
            DataFreshnessBadge(freshness: freshness),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(headline, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTypography.titleLarge.copyWith(color: colors.onSurface, height: 1.4)),
        if (summary.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs2),
          Text(summary, maxLines: 3, overflow: TextOverflow.ellipsis, style: AppTypography.bodyMedium.copyWith(color: colors.onSurfaceVariant, height: 1.55)),
        ],
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              l10n.tr('ai_news.official_daily.items').replaceAll('{count}', '${report.itemCount}'),
              style: AppTypography.labelMedium.copyWith(color: colors.onSurfaceVariant),
            ),
            Text('${report.date}${version == null ? '' : ' · API v$version'}', style: AppTypography.monoMeta.copyWith(color: colors.onSurfaceVariant)),
            FilledButton.tonalIcon(
              onPressed: () => context.go('/ai_news/daily/${report.date}'),
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: Text(l10n.tr('ai_news.official_daily.view')),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(l10n.tr('ai_news.official_daily.attribution'), style: AppTypography.bodySmall.copyWith(color: colors.onSurfaceVariant)),
      ],
    );
  }

  static String _headline(AiHotDailyReport report) {
    final lead = report.lead?.title.trim() ?? '';
    if (lead.isNotEmpty) {
      return lead;
    }
    for (final section in report.sections) {
      if (section.items.isNotEmpty) {
        return section.items.first.title;
      }
    }
    return report.flashes.isEmpty ? '' : report.flashes.first.title;
  }

  static String _summary(AiHotDailyReport report) {
    final lead = report.lead?.paragraph.trim() ?? '';
    if (lead.isNotEmpty) {
      return lead;
    }
    for (final section in report.sections) {
      if (section.items.isNotEmpty) {
        return section.items.first.summary;
      }
    }
    return '';
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.icon, required this.label, this.action});

  // 状态图标。
  final Widget icon;

  // 状态文案。
  final String label;

  // 可选恢复操作。
  final Widget? action;

  @override
  /* 构建紧凑状态行。 */
  Widget build(BuildContext context) {
    return Row(
      children: [
        icon,
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(label, style: AppTypography.bodyMedium.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant))),
        if (action != null) action!,
      ],
    );
  }
}
