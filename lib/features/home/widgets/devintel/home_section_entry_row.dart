import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

/// 首页情报总览入口行:5 个栏目跳转入口卡。
///
/// 视觉:5 张独立的浮动卡片,16px 间距,每张卡顶部一条 4px 语义色装饰条。
/// 替代旧版"5 个 tile 拼在一个共享外框里"的方案 —— 拼框视觉过重、且
/// 5 个 entry 之间没有真正的分隔需求。
class HomeSectionEntryRow extends ConsumerWidget {
  const HomeSectionEntryRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final specs = _buildSpecs(ref, context);
    return SizedBox(
      height: 168,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < specs.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.lg),
            Expanded(child: _EntryTile(spec: specs[i])),
          ],
        ],
      ),
    );
  }

  List<_EntrySpec> _buildSpecs(WidgetRef ref, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final aiItems = ref.watch(aiNewsItemsNotifierProvider).valueOrNull;
    final trending = ref.watch(trendingDigestProvider).valueOrNull;
    final hotspot = ref.watch(techHotspotDigestProvider).valueOrNull;
    final monitor = ref.watch(monitorDigestProvider).valueOrNull;
    final project = ref.watch(projectDigestProvider).valueOrNull;
    return [
      _EntrySpec(
        label: l10n.tr('home.entry.ai_news.label'),
        kpi:
            '${aiItems?.length ?? 0} ${l10n.tr('home.entry.ai_news.kpi_suffix')}',
        delta:
            _scoreDelta(l10n, aiItems?.fold<int>(0, (sum, e) => sum + e.score)),
        icon: Icons.auto_awesome_rounded,
        color: AppColors.brand,
        path: '/ai_news',
      ),
      _EntrySpec(
        label: l10n.tr('home.entry.trending.label'),
        kpi:
            '${trending?.allRepos.length ?? 0} ${l10n.tr('home.entry.trending.kpi_suffix')}',
        delta:
            '+${_compactNumber(trending?.trendingRepos.fold<int>(0, (sum, e) => sum + e.starDelta) ?? 0)}★',
        icon: Icons.local_fire_department_rounded,
        color: AppColors.warning,
        path: '/trending',
      ),
      _EntrySpec(
        label: l10n.tr('home.entry.hotspot.label'),
        kpi:
            '${hotspot?.topics.length ?? 0} ${l10n.tr('home.entry.hotspot.kpi_suffix')}',
        delta:
            '+${(hotspot?.topics.fold<double>(0, (sum, e) => sum + e.growth) ?? 0).toStringAsFixed(1)}%',
        icon: Icons.device_hub_rounded,
        color: AppColors.brand,
        path: '/tech_hotspot',
      ),
      _EntrySpec(
        label: l10n.tr('home.entry.monitor.label'),
        kpi:
            '${monitor?.stats.monitoredCount ?? 0} ${l10n.tr('home.entry.monitor.kpi_suffix')}',
        delta:
            '${monitor?.stats.unreadAlertCount ?? 0} ${l10n.tr('home.entry.monitor.delta_suffix')}',
        icon: Icons.notifications_rounded,
        color: AppColors.info,
        path: '/monitor',
      ),
      _EntrySpec(
        label: l10n.tr('home.entry.report.label'),
        kpi:
            '${project?.repos.length ?? 0} ${l10n.tr('home.entry.report.kpi_suffix')}',
        delta:
            '${project?.contributors.length ?? 0} ${l10n.tr('home.entry.report.delta_suffix')}',
        icon: Icons.insights_rounded,
        color: AppColors.success,
        path: '/project',
      ),
    ];
  }

  String _scoreDelta(AppLocalizations l10n, int? score) {
    if (score == null || score == 0) return l10n.tr('home.entry.syncing');
    return '+${_compactNumber(score)}';
  }

  String _compactNumber(int value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toString();
  }
}

class _EntrySpec {
  const _EntrySpec({
    required this.label,
    required this.kpi,
    required this.delta,
    required this.icon,
    required this.color,
    required this.path,
  });

  final String label;
  final String kpi;
  final String delta;
  final IconData icon;
  final Color color;
  final String path;
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.spec});

  final _EntrySpec spec;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Semantics(
      label: l10n
          .tr('a11y.entry_tile')
          .replaceAll('{label}', spec.label)
          .replaceAll('{kpi}', spec.kpi),
      button: true,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: colors.outlineVariant.withValues(alpha: isLight ? 0.58 : 1),
            width: 1,
          ),
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
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.xl,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: spec.color.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            alignment: Alignment.center,
                            child: Icon(spec.icon, size: 18, color: spec.color),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: colors.onSurfaceVariant,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        spec.label,
                        style: AppTypography.labelMedium.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        spec.kpi,
                        style: AppTypography.titleLarge.copyWith(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs2,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: spec.color.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                        ),
                        child: Text(
                          spec.delta,
                          style: AppTypography.labelSmall.copyWith(
                            color: spec.color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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

/// 顶部 4px 装饰条:水平方向用 [LinearGradient] 让两端淡出,避免硬切边。
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
            colors: [
              color.withValues(alpha: 0.0),
              color.withValues(alpha: 0.9),
              color.withValues(alpha: 0.0),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }
}
