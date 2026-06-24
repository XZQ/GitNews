import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../../shared/widgets/section_header.dart';

class DeveloperOptionsPage extends StatelessWidget {
  const DeveloperOptionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Scaffold(
      appBar: AppBar(
        title: Text(t.t('developerOptions.title')),
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
    final t = context.t;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: t.t('developerOptions.apiTitle'),
                subtitle: t.t('developerOptions.apiSubtitle'),
              ),
              const SizedBox(height: AppSpacing.md),
              _Row(
                  label: t.t('developerOptions.apiRow1'),
                  value: 'api.github.com'),
              _Row(label: t.t('developerOptions.apiRow2'), value: '10s'),
              _Row(label: t.t('developerOptions.apiRow3'), value: '2'),
              _Row(
                  label: t.t('developerOptions.apiRow4'),
                  value: t.t('app.light')),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: t.t('developerOptions.expTitle'),
                subtitle: t.t('developerOptions.expSubtitle'),
              ),
              const SizedBox(height: AppSpacing.md),
              _Row(label: t.t('developerOptions.expRow1'), value: 'OFF'),
              _Row(label: t.t('developerOptions.expRow2'), value: 'OFF'),
              _Row(label: t.t('developerOptions.expRow3'), value: 'BETA'),
            ],
          ),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(value, style: AppTypography.labelMedium),
        ],
      ),
    );
  }
}
