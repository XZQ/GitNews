import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/shared/local_content_controller.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../../shared/widgets/section_header.dart';

class MonitorRulesPage extends StatelessWidget {
  const MonitorRulesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tr('monitor.rules.title')),
        leading: BackButton(
          onPressed: () => context.canPop() ? context.pop() : context.go('/profile'),
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
    final content = ref.watch(localContentControllerProvider);
    final enabledFlags = content.monitorRules;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: l10n.tr('monitor.rules.title'),
                subtitle: l10n.tr('monitor.rules.enabled_count').replaceAll('{count}', '${content.enabledRuleCount}'),
              ),
              const SizedBox(height: AppSpacing.md),
              for (var i = 0; i < monitorRuleCount; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs2),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          monitorRuleLabels(l10n)[i],
                          style: AppTypography.bodyMedium,
                        ),
                      ),
                      Text(
                        enabledFlags[i] ? l10n.tr('monitor.rules.enabled') : l10n.tr('monitor.rules.disabled'),
                        style: AppTypography.labelSmall.copyWith(
                          color: enabledFlags[i] ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Switch(
                        value: enabledFlags[i],
                        onChanged: (value) => ref.read(localContentControllerProvider.notifier).setMonitorRule(i, value),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
