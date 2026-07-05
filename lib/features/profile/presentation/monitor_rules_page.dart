import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../../shared/widgets/section_header.dart';
import '../application/local_content_controller.dart';

class MonitorRulesPage extends StatelessWidget {
  const MonitorRulesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('监控规则'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/profile'),
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
                title: '监控规则',
                subtitle: '已启用 ${content.enabledRuleCount} 条',
              ),
              const SizedBox(height: AppSpacing.md),
              for (var i = 0; i < monitorRuleLabels.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs2),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          monitorRuleLabels[i],
                          style: AppTypography.bodyMedium,
                        ),
                      ),
                      Text(
                        enabledFlags[i] ? '已启用' : '已停用',
                        style: AppTypography.labelSmall.copyWith(
                          color: enabledFlags[i]
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Switch(
                        value: enabledFlags[i],
                        onChanged: (value) => ref
                            .read(localContentControllerProvider.notifier)
                            .setMonitorRule(i, value),
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
