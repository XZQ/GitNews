import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../../shared/widgets/secondary_page_scaffold.dart';
import '../../../shared/widgets/section_header.dart';
import 'widgets/github_token_card.dart';

class DeveloperOptionsPage extends ConsumerWidget {
  const DeveloperOptionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return SecondaryPageScaffold(
      title: l10n.tr('profile.dev_options.title'),
      subtitle: l10n.tr('profile.dev_options.subtitle'),
      icon: Icons.developer_mode_rounded,
      fallbackPath: '/profile',
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
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(title: l10n.tr('profile.dev_options.api_debug.title'), subtitle: l10n.tr('profile.dev_options.api_debug.subtitle')),
              const SizedBox(height: AppSpacing.md),
              _Row(label: l10n.tr('profile.dev_options.api_debug.endpoint'), value: 'api.github.com'),
              _Row(label: l10n.tr('profile.dev_options.api_debug.timeout'), value: '10s'),
              _Row(label: l10n.tr('profile.dev_options.api_debug.retries'), value: '2'),
              _Row(label: l10n.tr('profile.dev_options.api_debug.theme'), value: l10n.tr('profile.dev_options.api_debug.theme_light')),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const GitHubTokenCard(),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(title: l10n.tr('profile.dev_options.experiments.title'), subtitle: l10n.tr('profile.dev_options.experiments.subtitle')),
              const SizedBox(height: AppSpacing.md),
              _Row(label: l10n.tr('profile.dev_options.experiments.cache_strategy'), value: 'OFF'),
              _Row(label: l10n.tr('profile.dev_options.experiments.realtime_trending'), value: 'OFF'),
              _Row(label: l10n.tr('profile.dev_options.experiments.ai_summary'), value: 'BETA'),
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
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: AppTypography.bodyMedium.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
          Text(value, style: AppTypography.labelMedium),
        ],
      ),
    );
  }
}
