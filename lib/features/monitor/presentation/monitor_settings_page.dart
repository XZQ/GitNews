import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/app_localizations.dart';
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
        title: Text(context.t.t('monitor.settingsAppBar')),
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
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: context.t.t('monitor.settings.chTitle'),
                subtitle: context.t.t('monitor.settings.chSubtitle'),
              ),
              const SizedBox(height: AppSpacing.md),
              _NotifRow(labelKey: 'monitor.settings.chRow1', value: true),
              _NotifRow(labelKey: 'monitor.settings.chRow2', value: false),
              _NotifRow(labelKey: 'monitor.settings.chRow3', value: true),
              _NotifRow(labelKey: 'monitor.settings.chRow4', value: false),
              _NotifRow(labelKey: 'monitor.settings.chRow5', value: true),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: context.t.t('monitor.settings.dndTitle'),
                subtitle: context.t.t('monitor.settings.dndSubtitle'),
              ),
              const SizedBox(height: AppSpacing.md),
              _NotifRow(labelKey: 'monitor.settings.dndRow1', value: true),
              _NotifRow(labelKey: 'monitor.settings.dndRow2', value: false),
            ],
          ),
        ),
      ],
    );
  }
}

class _NotifRow extends StatelessWidget {
  const _NotifRow({required this.labelKey, required this.value});
  final String labelKey;
  final bool value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              context.t.t(labelKey),
              style: AppTypography.bodyMedium,
            ),
          ),
          Switch(value: value, onChanged: (_) {}),
        ],
      ),
    );
  }
}
