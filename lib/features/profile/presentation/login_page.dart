import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/api_endpoints_config.dart';
import '../../../core/github/github_device_flow_controller.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../../shared/widgets/section_header.dart';
import 'widgets/device_flow_content.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tr(ApiEndpointsConfig.githubOAuthConfigured ? 'device_flow.title' : 'profile.token.title')),
        leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go('/profile')),
      ),
      body: ResponsiveLayout(
        compact: (_) => const _Body(),
        medium: (_) => const CenteredContent(maxWidth: 480, child: _Body()),
        expanded: (_) => const CenteredContent(maxWidth: 480, child: _Body()),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    if (!ApiEndpointsConfig.githubOAuthConfigured) {
      return _PatFallback(l10n: l10n);
    }
    ref.listen<DeviceFlowState>(githubDeviceFlowProvider, (prev, next) {
      if (next.status == DeviceFlowStatus.success) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) context.go('/profile');
        });
      }
    });
    final state = ref.watch(githubDeviceFlowProvider);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [SectionHeader(title: l10n.tr('device_flow.title'), subtitle: l10n.tr('device_flow.subtitle')), const SizedBox(height: AppSpacing.lg), DeviceFlowContent(state: state)],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(title: l10n.tr('profile.login.why_login'), subtitle: l10n.tr('profile.login.why_login.subtitle')),
              const SizedBox(height: AppSpacing.md),
              _Bullet(l10n.tr('profile.login.bullet.sync')),
              _Bullet(l10n.tr('profile.login.bullet.cross_device')),
              _Bullet(l10n.tr('profile.login.bullet.api_quota'))
            ],
          ),
        )
      ],
    );
  }
}

class _PatFallback extends StatelessWidget {
  const _PatFallback({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(title: l10n.tr('profile.token.title'), subtitle: l10n.tr('profile.token.subtitle')),
              const SizedBox(height: AppSpacing.md),
              Text(l10n.tr('profile.token.security_notice'), style: AppTypography.bodyMedium),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => context.go('/profile/developer'),
                  icon: const Icon(Icons.key_rounded),
                  label: Text(l10n.tr('profile.login.configure_pat')),
                ),
              )
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(title: l10n.tr('profile.login.why_login'), subtitle: l10n.tr('profile.login.why_login.subtitle')),
              const SizedBox(height: AppSpacing.md),
              _Bullet(l10n.tr('profile.login.bullet.sync')),
              _Bullet(l10n.tr('profile.login.bullet.api_quota'))
            ],
          ),
        )
      ],
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 16,
            color: AppColors.success,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text, style: AppTypography.bodyMedium))
        ],
      ),
    );
  }
}
