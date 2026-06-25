import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/bordered_row.dart';

/// 首页情报总览入口行:5 个栏目跳转 + KPI。
class HomeSectionEntryRow extends StatelessWidget {
  const HomeSectionEntryRow({super.key});

  @override
  Widget build(BuildContext context) {
    return const BorderedRow(
      children: [
        _EntryTile(spec: _aiNews),
        _EntryTile(spec: _trending),
        _EntryTile(spec: _hotspot),
        _EntryTile(spec: _monitor),
        _EntryTile(spec: _report),
      ],
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
  label: 'AI 资讯',
  kpi: '10 条新更',
  delta: '+18%',
  icon: Icons.auto_awesome_rounded,
  color: AppColors.brand,
  path: '/ai_news',
);
const _trending = _EntrySpec(
  label: 'GitHub 热榜',
  kpi: '36 个项目',
  delta: '+1.2K★',
  icon: Icons.local_fire_department_rounded,
  color: AppColors.warning,
  path: '/trending',
);
const _hotspot = _EntrySpec(
  label: '技术热点',
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

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.spec});

  final _EntrySpec spec;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go(spec.path),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: spec.color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    alignment: Alignment.center,
                    child: Icon(spec.icon, size: 16, color: spec.color),
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
              const SizedBox(height: 4),
              Text(
                spec.kpi,
                style: AppTypography.titleLarge.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm - 1,
                      vertical: 2,
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
            ],
          ),
        ),
      ),
    );
  }
}
