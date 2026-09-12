import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/domain/observed_repo_growth.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../ai_news/application/ai_news_providers.dart';
import '../../../monitor/application/monitor_providers.dart';
import '../../../project/application/project_providers.dart';
import '../../../tech_hotspot/application/tech_hotspot_providers.dart';
import '../../../trending/application/trending_providers.dart';

/*
*首页五个栏目入口，按可用宽度和字号换行，指标只描述已加载样本。
*/
class HomeSectionEntryRow extends ConsumerWidget {
  const HomeSectionEntryRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final specs = _buildSpecs(ref, context);
    return LayoutBuilder(
      builder: (context, constraints) {
        // 五个轻量入口按行等高；不限制高度，让大字号与指标说明自然增长。
        final minWidth = MediaQuery.textScalerOf(context).scale(200);
        final columns = ((constraints.maxWidth + AppSpacing.lg) / (minWidth + AppSpacing.lg)).floor().clamp(1, specs.length);
        return Column(
          children: [
            for (var start = 0; start < specs.length; start += columns) ...[
              if (start > 0) const SizedBox(height: AppSpacing.lg),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var offset = 0; offset < columns; offset++) ...[
                      if (offset > 0) const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: start + offset < specs.length ? _EntryTile(key: ValueKey(specs[start + offset].path), spec: specs[start + offset]) : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  List<_EntrySpec> _buildSpecs(WidgetRef ref, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final aiState = ref.watch(aiNewsItemsNotifierProvider);
    final trendingState = ref.watch(trendingDigestProvider);
    final hotspotState = ref.watch(techHotspotDigestProvider);
    final monitorState = ref.watch(visibleMonitorDigestProvider);
    final projectState = ref.watch(projectDigestProvider);
    final aiItems = aiState.value;
    final trending = trendingState.value;
    final hotspot = hotspotState.value;
    final monitor = monitorState.value;
    final project = projectState.value;
    final growth = trending == null ? null : ObservedRepoGrowth.fromRepos(trending.allRepos, now: ref.watch(trendingClockProvider)());
    return [
      _EntrySpec(
        label: l10n.tr('home.entry.ai_news.label'),
        kpi: _count(l10n, aiItems?.length, 'ai_news'),
        delta: _context(
          l10n,
          aiState,
          l10n.tr('home.entry.ai_news.sources').replaceAll('{count}', '${aiItems?.map((item) => item.source.trim().toLowerCase()).where((source) => source.isNotEmpty).toSet().length ?? 0}'),
        ),
        icon: Icons.auto_awesome_rounded,
        color: AppColors.brand,
        path: '/ai_news',
      ),
      _EntrySpec(
        label: l10n.tr('home.entry.trending.label'),
        kpi: _count(l10n, growth?.totalCount, 'trending'),
        delta: _context(l10n, trendingState, _growthText(l10n, growth)),
        icon: Icons.local_fire_department_rounded,
        color: AppColors.warning,
        path: '/trending',
      ),
      _EntrySpec(
        label: l10n.tr('home.entry.hotspot.label'),
        kpi: _count(l10n, hotspot?.topics.length, 'hotspot'),
        delta: _context(l10n, hotspotState, l10n.tr('home.entry.current_sample')),
        icon: Icons.device_hub_rounded,
        color: AppColors.brand,
        path: '/tech_hotspot',
      ),
      _EntrySpec(
        label: l10n.tr('home.entry.monitor.label'),
        kpi: _count(l10n, monitor?.stats.monitoredCount, 'monitor'),
        delta: _context(l10n, monitorState, '${monitor?.stats.unreadAlertCount ?? 0} ${l10n.tr('home.entry.monitor.delta_suffix')}'),
        icon: Icons.notifications_rounded,
        color: AppColors.info,
        path: '/monitor',
      ),
      _EntrySpec(
        label: l10n.tr('home.entry.report.label'),
        kpi: _count(l10n, project?.repos.length, 'report'),
        delta: _context(l10n, projectState, '${project?.contributors.length ?? 0} ${l10n.tr('home.entry.report.delta_suffix')}'),
        icon: Icons.insights_rounded,
        color: AppColors.success,
        path: '/project',
      ),
    ];
  }

  /* 尚未取得数据时保留未知值，成功的空集合才显示零。 */
  String _count(AppLocalizations l10n, int? value, String section) => value == null ? '—' : '$value ${l10n.tr('home.entry.$section.kpi_suffix')}';

  /* 保留已有样本，同时说明刷新或失败状态。 */
  String _context(AppLocalizations l10n, AsyncValue<Object?> state, String detail) {
    final status = state.hasError ? l10n.tr('home.entry.unavailable') : l10n.tr('home.entry.syncing');
    if (!state.hasValue) return status;
    return state.isLoading || state.hasError ? '$detail · $status' : detail;
  }

  /* 只展示共同 UTC 日期下同一组仓库的净变化。 */
  String _growthText(AppLocalizations l10n, ObservedRepoGrowth? growth) {
    if (growth == null || growth.isEmpty) return l10n.tr('home.entry.growth_pending');
    final value = growth.netChange!;
    return l10n
        .tr('home.entry.growth_observed')
        .replaceAll('{value}', '${value > 0 ? '+' : ''}$value')
        .replaceAll('{sample}', '${growth.sampleCount}/${growth.totalCount}')
        .replaceAll('{start}', growth.dates.first.toIso8601String().substring(0, 10))
        .replaceAll('{end}', growth.dates.last.toIso8601String().substring(0, 10));
  }
}

class _EntrySpec {
  const _EntrySpec({required this.label, required this.kpi, required this.delta, required this.icon, required this.color, required this.path});

  final String label;
  final String kpi;
  final String delta;
  final IconData icon;
  final Color color;
  final String path;
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.spec, super.key});

  final _EntrySpec spec;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Semantics(
      label: l10n.tr('a11y.entry_tile').replaceAll('{label}', spec.label).replaceAll('{kpi}', spec.kpi),
      button: true,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: colors.outlineVariant.withValues(alpha: isLight ? 0.58 : 1), width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.go(spec.path),
            focusColor: colors.primary.withValues(alpha: 0.12),
            child: Stack(
              children: [
                Positioned.fill(child: _AccentStrip(color: spec.color)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(color: spec.color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(AppRadius.sm)),
                            alignment: Alignment.center,
                            child: Icon(spec.icon, size: 18, color: spec.color),
                          ),
                          const Spacer(),
                          Icon(Icons.chevron_right_rounded, size: 18, color: colors.onSurfaceVariant),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        spec.label,
                        style: AppTypography.labelMedium.copyWith(color: colors.onSurfaceVariant, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        spec.kpi,
                        style: AppTypography.titleLarge.copyWith(color: colors.onSurface, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs2, vertical: AppSpacing.xs),
                        decoration: BoxDecoration(color: spec.color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(AppRadius.xs)),
                        child: Text(spec.delta, style: AppTypography.bodySmall.copyWith(color: colors.onSurfaceVariant)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* 
*顶部 4px 装饰条:水平方向用 [LinearGradient] 让两端淡出,避免硬切边。
*/
class _AccentStrip extends StatelessWidget {
  const _AccentStrip({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        height: 4,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [color.withValues(alpha: 0.0), color.withValues(alpha: 0.9), color.withValues(alpha: 0.0)],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }
}
