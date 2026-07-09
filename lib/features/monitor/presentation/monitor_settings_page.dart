import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../../shared/widgets/section_header.dart';
import '../application/monitor_settings_controller.dart';
import '../widgets/monitor_settings_cards.dart';

/* 
*通知设置。
*/
class MonitorSettingsPage extends StatelessWidget {
  const MonitorSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tr('monitor.settings.title')),
        leading: BackButton(
          onPressed: () => context.canPop() ? context.pop() : context.go('/monitor'),
        ),
      ),
      body: ResponsiveLayout(
        compact: (_) => const _Body(),
        medium: (_) => const CenteredContent(child: _Body()),
        expanded: (_) => const CenteredContent(child: _Body()),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final values = ref.watch(monitorSettingsControllerProvider);
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
                title: l10n.tr('monitor.settings.channel'),
                subtitle: l10n.tr('monitor.settings.channel_subtitle'),
              ),
              const SizedBox(height: AppSpacing.md),
              for (var i = 0; i < 5; i++)
                MonitorNotificationRow(
                  label: monitorNotificationLabels(l10n)[i],
                  value: values[i],
                  onChanged: (value) => ref.read(monitorSettingsControllerProvider.notifier).setEnabled(i, value),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: l10n.tr('monitor.settings.dnd'),
                subtitle: l10n.tr('monitor.settings.dnd_subtitle'),
              ),
              const SizedBox(height: AppSpacing.md),
              for (var i = 5; i < monitorNotificationCount; i++)
                MonitorNotificationRow(
                  label: monitorNotificationLabels(l10n)[i],
                  value: values[i],
                  onChanged: (value) => ref.read(monitorSettingsControllerProvider.notifier).setEnabled(i, value),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
