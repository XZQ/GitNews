import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    const rules = [
      'Star 增速 ≥ 200/天',
      '单日增长 ≥ 10%',
      'Fork 增速 ≥ 50/天',
      '讨论热度 ≥ 5x',
    ];
    const enabledFlags = [true, true, false, true];
    final enabledCount = enabledFlags.where((e) => e).length;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: '监控规则',
                subtitle: '已启用 $enabledCount 条',
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ).copyChildren([
            for (var i = 0; i < rules.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        rules[i],
                        style: AppTypography.bodyMedium,
                      ),
                    ),
                    Text(
                      enabledFlags[i] ? '已启用' : '已禁用',
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
