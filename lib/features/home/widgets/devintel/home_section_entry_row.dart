import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// 首页情报总览入口行:5 个栏目跳转入口卡。
///
/// 视觉:5 张独立的浮动卡片,16px 间距,每张卡顶部一条 4px 语义色装饰条。
/// 替代旧版"5 个 tile 拼在一个共享外框里"的方案 —— 拼框视觉过重、且
/// 5 个 entry 之间没有真正的分隔需求。
class HomeSectionEntryRow extends StatelessWidget {
  const HomeSectionEntryRow({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 168,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < _specs.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.lg),
            Expanded(child: _EntryTile(spec: _specs[i])),
          ],
        ],
      ),
    );
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

const _aiNews = _EntrySpec(
  label: 'AI 动态',
  kpi: '10 条新更',
  delta: '+18%',
  icon: Icons.auto_awesome_rounded,
  color: AppColors.brand,
  path: '/ai_news',
);
const _trending = _EntrySpec(
  label: 'GitHub热榜',
  kpi: '36 个项目',
  delta: '+1.2K★',
  icon: Icons.local_fire_department_rounded,
  color: AppColors.warning,
  path: '/trending',
);
const _hotspot = _EntrySpec(
  label: '技术趋势',
  kpi: '8 主题',
  delta: '+24%',
  icon: Icons.whatshot_rounded,
  color: AppColors.danger,
  path: '/tech_hotspot',
);
const _monitor = _EntrySpec(
  label: '仓库监控',
  kpi: '12 订阅',
  delta: '3 告警',
  icon: Icons.notifications_rounded,
  color: AppColors.info,
  path: '/monitor',
);
const _report = _EntrySpec(
  label: '深度报告',
  kpi: '4 份周报',
  delta: '更新',
  icon: Icons.insights_rounded,
  color: AppColors.success,
  path: '/project',
);

const _specs = [_aiNews, _trending, _hotspot, _monitor, _report];

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.spec});

  final _EntrySpec spec;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: isLight ? 0.58 : 1),
          width: isLight ? 0.6 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go(spec.path),
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
