import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../../shared/widgets/section_header.dart';

class MonitorRulesPage extends StatelessWidget {
  const MonitorRulesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t.t('monitorRules.title')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/profile'),
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
    final ruleKeys = const [
      'monitor.rule.1',
      'monitor.rule.2',
      'monitor.rule.3',
      'monitor.rule.4',
    ];
    final enabledFlags = const [true, true, false, true];
    final enabledCount = enabledFlags.where((e) => e).length;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: context.t.t('monitorRules.title'),
                subtitle: context.t
                    .tr('monitorRules.subtitleFull', {'count': enabledCount}),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ).copyChildren([
            for (var i = 0; i < ruleKeys.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.t.t(ruleKeys[i]),
                        style: AppTypography.bodyMedium,
                      ),
                    ),
                    Text(
                      context.t.t(enabledFlags[i]
                          ? 'monitorRules.enabled'
                          : 'monitorRules.disabled'),
                      style: AppTypography.labelSmall.copyWith(
                        color: enabledFlags[i]
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Switch(value: enabledFlags[i], onChanged: (_) {}),
                  ],
                ),
              ),
          ]),
        ),
      ],
    );
  }
}

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
