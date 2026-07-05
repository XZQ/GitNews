import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/section_header.dart';
import '../../profile/application/local_content_controller.dart';
import '../application/monitor_settings_controller.dart';

class MonitorRulesCard extends ConsumerWidget {
  const MonitorRulesCard({this.query = '', super.key});

  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final content = ref.watch(localContentControllerProvider);
    final allRules = <MonitorRuleItem>[
      MonitorRuleItem(monitorRuleLabels[0], AppColors.success, 0),
      MonitorRuleItem(monitorRuleLabels[1], colors.primary, 1),
      MonitorRuleItem(monitorRuleLabels[2], AppColors.info, 2),
      MonitorRuleItem(monitorRuleLabels[3], AppColors.warning, 3),
    ];
    final keyword = query.trim().toLowerCase();
    final rules = keyword.isEmpty
        ? allRules
        : [
            for (final rule in allRules)
              if (rule.label.toLowerCase().contains(keyword) ||
                  '监控规则'.contains(keyword))
                rule,
          ];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: '监控规则',
            subtitle: '${content.enabledRuleCount} 条已启用',
          ),
          const SizedBox(height: AppSpacing.md),
          if (rules.isEmpty)
            const EmptyView(
              icon: Icons.rule_folder_outlined,
              message: '没有匹配的监控规则',
            )
          else
            for (final rule in rules) _RuleRow(rule: rule),
        ],
      ),
    );
  }
}

class MonitorNotificationCard extends ConsumerWidget {
  const MonitorNotificationCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final values = ref.watch(monitorSettingsControllerProvider);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: '通知设置',
            subtitle: '推送渠道与频次',
          ),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < 4; i++)
            MonitorNotificationRow(
              label: monitorNotificationLabels[i],
              value: values[i],
              onChanged: (value) => ref
                  .read(monitorSettingsControllerProvider.notifier)
                  .setEnabled(i, value),
            ),
        ],
      ),
    );
  }
}

class MonitorNotificationRow extends StatelessWidget {
  const MonitorNotificationRow({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTypography.bodyMedium)),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class MonitorRuleItem {
  const MonitorRuleItem(this.label, this.color, this.index);

  final String label;
  final Color color;
  final int index;
}

class _RuleRow extends ConsumerWidget {
  const _RuleRow({required this.rule});

  final MonitorRuleItem rule;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled =
        ref.watch(localContentControllerProvider).monitorRules[rule.index];
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
          Switch(
            value: enabled,
            onChanged: (value) => ref
                .read(localContentControllerProvider.notifier)
                .setMonitorRule(rule.index, value),
          ),
        ],
      ),
    );
  }
}
