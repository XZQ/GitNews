import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/demo_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/star_trend_chart.dart';

class MonitorPage extends StatelessWidget {
  const MonitorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('监控')),
      body: ResponsiveLayout(
        compact: (_) => const _Mobile(),
        medium: (_) => const _Desktop(),
        expanded: (_) => const _Desktop(),
      ),
    );
  }
}

/// 手机:状态 4 卡 + 我的监控仓库 + 最近告警。
class _Mobile extends StatelessWidget {
  const _Mobile();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      children: const [
        _StatusRow(),
        SizedBox(height: AppSpacing.lg),
        _MonitoredRepos(),
        SizedBox(height: AppSpacing.lg),
        _RecentAlerts(),
      ],
    );
  }
}

/// 桌面:左 8 列监控仓库表 + 告警 / 右 4 列(规则 + 通知设置)。
class _Desktop extends StatelessWidget {
  const _Desktop();

  @override
  Widget build(BuildContext context) {
    return CenteredContent(
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        children: const [
          _StatusRow(),
          SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 8, child: _MonitoredRepos()),
              SizedBox(width: AppSpacing.lg),
              Expanded(flex: 4, child: _RightColumn()),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatusCard(
            label: '监控仓库',
            value: '28',
            delta: '+4',
            icon: Icons.visibility_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        const Expanded(
          child: _StatusCard(
            label: '未读告警',
            value: '4',
            delta: '-2',
            icon: Icons.error_outline,
            color: AppColors.warning,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        const Expanded(
          child: _StatusCard(
            label: '今日触发',
            value: '3',
            delta: '+1',
            icon: Icons.bolt_rounded,
            color: AppColors.info,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        const Expanded(
          child: _StatusCard(
            label: '告警总数',
            value: '12',
            delta: '-5',
            icon: Icons.history_rounded,
            color: AppColors.success,
          ),
        ),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.label,
    required this.value,
    required this.delta,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final String delta;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTypography.headlineMedium.copyWith(
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            delta,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MonitoredRepos extends StatelessWidget {
  const _MonitoredRepos();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xs,
            ),
            child: SectionHeader(
              title: '我的监控仓库',
              subtitle: '近 30 天 Star 增速与告警',
            ),
          ),
          for (var i = 0; i < DemoData.trending.length; i++) ...[
            if (i != 0) const Divider(height: 1),
            _MonitoredRow(repo: DemoData.trending[i]),
          ],
        ],
      ),
    );
  }
}

class _MonitoredRow extends StatelessWidget {
  const _MonitoredRow({required this.repo});
  final DemoRepo repo;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => context.go(
        '/repo_detail/${Uri.encodeComponent(repo.fullName)}',
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Color(repo.color).withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                repo.language[0],
                style: AppTypography.labelMedium.copyWith(
                  color: Color(repo.color),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(repo.fullName, style: AppTypography.titleSmall),
                  Text(
                    repo.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelSmall.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 90,
              child: StarTrendChart(
                series: [
                  ChartSeries(
                    values: DemoData.generateStarTrend(
                      repo.starCount - 5000,
                      5000,
                    ),
                    color: AppColors.success,
                  ),
                ],
                height: 40,
                showArea: false,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '正常',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentAlerts extends StatelessWidget {
  const _RecentAlerts();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xs,
            ),
            child: SectionHeader(
              title: '最近告警',
              subtitle: '今日与昨日告警流',
            ),
          ),
          for (var i = 0; i < DemoData.alerts.length; i++) ...[
            if (i != 0) const Divider(height: 1),
            _AlertRow(alert: DemoData.alerts[i]),
          ],
        ],
      ),
    );
  }
}

class _AlertRow extends StatelessWidget {
  const _AlertRow({required this.alert});
  final DemoAlert alert;

  Color _accent() {
    return switch (alert.severity) {
      AlertSeverity.success => AppColors.success,
      AlertSeverity.warning => AppColors.warning,
      AlertSeverity.danger => AppColors.danger,
      AlertSeverity.info => AppColors.info,
    };
  }

  IconData _icon() {
    return switch (alert.severity) {
      AlertSeverity.success => Icons.trending_up_rounded,
      AlertSeverity.warning => Icons.warning_amber_rounded,
      AlertSeverity.danger => Icons.error_outline,
      AlertSeverity.info => Icons.info_outline,
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = _accent();
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_icon(), color: color, size: 18),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alert.repo, style: AppTypography.titleSmall),
                Text(
                  alert.metric,
                  style: AppTypography.bodySmall.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            alert.value,
            style: AppTypography.labelMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            alert.time,
            style: AppTypography.labelSmall.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _RightColumn extends StatelessWidget {
  const _RightColumn();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _RulesCard(),
        SizedBox(height: AppSpacing.lg),
        _NotificationCard(),
        SizedBox(height: AppSpacing.lg),
        _RecentAlerts(),
      ],
    );
  }
}

class _RulesCard extends StatelessWidget {
  const _RulesCard();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final rules = <(String, Color, bool)>[
      ('Star 增速 ≥ 200/天', AppColors.success, true),
      ('单日增长 ≥ 10%', colors.primary, true),
      ('Fork 增速 ≥ 50/天', AppColors.info, false),
      ('讨论热度 ≥ 5x', AppColors.warning, true),
    ];
    return AppCard(
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: '监控规则',
            subtitle: '3 ${'条'}',
          ),
          SizedBox(height: AppSpacing.md),
        ],
      ).copyChildren([
        for (final r in rules)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: r.$2,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(r.$1, style: AppTypography.bodyMedium)),
                Switch(value: r.$3, onChanged: (_) {}),
              ],
            ),
          ),
      ]),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard();

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: '通知设置',
            subtitle: '推送渠道与频次',
          ),
          SizedBox(height: AppSpacing.md),
          _NotifRow(label: '应用内通知', value: true),
          _NotifRow(label: '邮件摘要', value: false),
          _NotifRow(label: '每日报告', value: true),
          _NotifRow(label: '周报推送', value: false),
        ],
      ),
    );
  }
}

class _NotifRow extends StatelessWidget {
  const _NotifRow({required this.label, required this.value});
  final String label;
  final bool value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTypography.bodyMedium)),
          Switch(value: value, onChanged: (_) {}),
        ],
      ),
    );
  }
}

/// 调试用扩展:在 const Column 中拼接额外子项。
extension _ColumnCopy on Column {
  Column copyChildren(List<Widget> extra) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      mainAxisAlignment: mainAxisAlignment,
      children: [...children, ...extra],
    );
  }
}
