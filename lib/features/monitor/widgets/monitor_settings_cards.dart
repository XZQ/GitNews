import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/section_header.dart';

class MonitorRulesCard extends StatelessWidget {
  const MonitorRulesCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final rules = <MonitorRuleItem>[
      const MonitorRuleItem('Star 增速 ≥ 200/天', AppColors.success, true),
      MonitorRuleItem('单日增长 ≥ 10%', colors.primary, true),
      const MonitorRuleItem('Fork 增速 ≥ 50/天', AppColors.info, false),
      const MonitorRuleItem('讨论热度 ≥ 5x', AppColors.warning, true),
    ];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: '监控规则',
            subtitle: '3 条',
          ),
          const SizedBox(height: AppSpacing.md),
          for (final rule in rules) _RuleRow(rule: rule),
        ],
      ),
    );
  }
}

class MonitorNotificationCard extends StatelessWidget {
  const MonitorNotificationCard({super.key});

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
          MonitorNotificationRow(label: '应用内通知', value: true),
          MonitorNotificationRow(label: '邮件摘要', value: false),
          MonitorNotificationRow(label: '每日报告', value: true),
          MonitorNotificationRow(label: '周报推送', value: false),
        ],
      ),
    );
  }
}

class MonitorNotificationRow extends StatelessWidget {
  const MonitorNotificationRow({
    required this.label,
    required this.value,
    super.key,
  });

  final String label;
  final bool value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTypography.bodyMedium)),
          Switch(value: value, onChanged: (_) {}),
        ],
      ),
    );
  }
}

class MonitorRuleItem {
  const MonitorRuleItem(this.label, this.color, this.isEnabled);

  final String label;
  final Color color;
  final bool isEnabled;
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({required this.rule});

  final MonitorRuleItem rule;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs2),
      child: Row(
        children: [
          Container(
            width: AppSpacing.sm,
            height: AppSpacing.sm,
            decoration: BoxDecoration(
              color: rule.color,
              borderRadius: BorderRadius.circular(AppRadius.dot),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(rule.label, style: AppTypography.bodyMedium)),
          Switch(value: rule.isEnabled, onChanged: (_) {}),
        ],
      ),
    );
  }
}
