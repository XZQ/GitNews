import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../../shared/widgets/section_header.dart';

/// 通知设置。
class MonitorSettingsPage extends StatelessWidget {
  const MonitorSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('通知设置'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/monitor'),
        ),
      ),
      body: ResponsiveLayout(
        compact: (_) => const _Body(),
        medium: (_) => CenteredContent(child: const _Body()),
        expanded: (_) => CenteredContent(child: const _Body()),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

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
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(title: '通知渠道', subtitle: '应用内 / 邮件 / 推送'),
              SizedBox(height: AppSpacing.md),
              _NotifRow(label: '应用内通知', value: true),
              _NotifRow(label: '邮件摘要', value: false),
              _NotifRow(label: '每日报告', value: true),
              _NotifRow(label: '周报推送', value: false),
              _NotifRow(label: '仅关键告警', value: true),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.lg),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(title: '免打扰', subtitle: '夜间与工作时段'),
              SizedBox(height: AppSpacing.md),
              _NotifRow(label: '夜间 22:00 - 08:00 静默', value: true),
              _NotifRow(label: '工作时段仅推送关键', value: false),
            ],
          ),
        ),
      ],
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
