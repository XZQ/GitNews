import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/repo_tile.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/star_trend_chart.dart';
import '../application/trending_providers.dart';
import '../domain/trending_repository.dart';
import 'trending_metrics.dart';
import 'trending_topics_panel.dart';

/*
*手机:时间窗 / 筛选 + Hero 趋势图 + 列表 + 趋势主题。
*/
class TrendingMobileView extends ConsumerWidget {
  const TrendingMobileView({required this.digest, super.key});

  final TrendingDigest digest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final window = ref.watch(trendingWindowFilterProvider);
    final lang = ref.watch(trendingLanguageFilterProvider);
    final windowLabel = _windowLabel(l10n, window);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(l10n.tr('trending.mobile.star_growth_rank'), style: AppTypography.titleLarge),
                  ),
                  TrendingPopupMenu(
                    value: lang,
                    options: const ['all', 'typescript', 'python', 'rust'],
                    optionLabel: (v) => _languageLabel(l10n, v),
                    onSelected: (v) => ref.read(trendingLanguageFilterProvider.notifier).state = v,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.tr('trending.mobile.tracking_subtitle').replaceAll('{window}', windowLabel),
                style: AppTypography.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TrendingWindowSegmented(
                value: window,
                onChanged: (v) => ref.read(trendingWindowFilterProvider.notifier).state = v,
              ),
              const SizedBox(height: AppSpacing.md),
              const TrendingHeroMetrics(),
              const SizedBox(height: AppSpacing.md),
              StarTrendChart(
                series: [
                  ChartSeries(
                    values: digest.primaryTrend,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  ChartSeries(
                    values: digest.secondaryTrend,
                    color: AppColors.success,
                  ),
                ],
                height: 200,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.xs,
                ),
                child: SectionHeader(
                  title: l10n.tr('trending.page.repos'),
                  subtitle: l10n.tr('trending.mobile.repos_count').replaceAll('{window}', windowLabel).replaceAll('{count}', '${digest.trendingRepos.length}'),
                  trailing: TextButton(
                    onPressed: () => _showFilterSheet(context, ref),
                    child: Text(l10n.tr('trending.action.filter')),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.xs,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: digest.trendingRepos.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, i) {
                    final repo = digest.trendingRepos[i];
                    return RepoTile(
                      repo: repo,
                      rank: i + 1,
                      onTap: () => context.go(
                        '/trending/detail/${Uri.encodeComponent(repo.fullName)}',
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const TrendingTopicsPanel(),
      ],
    );
  }
}

String _windowLabel(AppLocalizations l10n, String window) => switch (window) {
      'today' => l10n.tr('trending.window.today'),
      'week' => l10n.tr('trending.window.week'),
      'month' => l10n.tr('trending.window.month'),
      _ => l10n.tr('trending.window.today'),
    };

String _languageLabel(AppLocalizations l10n, String code) => switch (code) {
      'all' => l10n.tr('trending.language.all'),
      'dart' => 'Dart',
      'typescript' => 'TypeScript',
      'python' => 'Python',
      'rust' => 'Rust',
      'go' => 'Go',
      _ => code,
    };

const _windowOptionKeys = ['today', 'week', 'month'];
const _languageOptionKeys = ['all', 'dart', 'typescript', 'python', 'rust', 'go'];

Future<void> _showFilterSheet(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  await showModalBottomSheet<void>(
    context: context,
    builder: (sheetCtx) => StatefulBuilder(
      builder: (sheetCtx, setSheetState) {
        final window = ref.read(trendingWindowFilterProvider);
        final lang = ref.read(trendingLanguageFilterProvider);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.tr('trending.mobile.time_window'), style: AppTypography.titleMedium),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final key in _windowOptionKeys)
                      ChoiceChip(
                        label: Text(_windowLabel(l10n, key)),
                        selected: window == key,
                        onSelected: (_) {
                          ref.read(trendingWindowFilterProvider.notifier).state = key;
                          setSheetState(() {});
                        },
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(l10n.tr('trending.mobile.language'), style: AppTypography.titleMedium),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final key in _languageOptionKeys)
                      ChoiceChip(
                        label: Text(_languageLabel(l10n, key)),
                        selected: lang == key,
                        onSelected: (_) {
                          ref.read(trendingLanguageFilterProvider.notifier).state = key;
                          setSheetState(() {});
                        },
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(sheetCtx).pop(),
                    child: Text(l10n.tr('common.done')),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
