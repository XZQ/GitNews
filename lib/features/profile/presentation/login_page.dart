import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../../shared/widgets/section_header.dart';

/// 登录页(预留入口,匿名优先)。
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t.t('login.title')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/profile'),
        ),
      ),
      body: ResponsiveLayout(
        compact: (_) => const _Body(),
        medium: (_) => CenteredContent(maxWidth: 480, child: const _Body()),
        expanded: (_) => CenteredContent(maxWidth: 480, child: const _Body()),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: context.t.t('login.headerTitle'),
                subtitle: context.t.t('login.headerSubtitle'),
              ),
              const SizedBox(height: AppSpacing.lg),
              _InputField(
                labelKey: 'login.username',
                hint: 'your-name',
              ),
              const SizedBox(height: AppSpacing.md),
              _InputField(
                labelKey: 'login.password',
                hint: '********',
                obscure: true,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ).copyChildren([
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {},
                child: Text(context.t.t('login.submit')),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.code, size: 16),
                label: Text(context.t.t('login.withGithub')),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: Text(
                context.t.t('login.agreement'),
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textMutedLight,
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: context.t.t('login.whyTitle'),
                subtitle: context.t.t('login.whySubtitle'),
              ),
              const SizedBox(height: AppSpacing.md),
              _Bullet('login.whyB1'),
              _Bullet('login.whyB2'),
              _Bullet('login.whyB3'),
            ],
          ),
        ),
      ],
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.labelKey,
    required this.hint,
    this.obscure = false,
  });

  final String labelKey;
  final String hint;
  final bool obscure;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.t.t(labelKey), style: AppTypography.labelMedium),
        const SizedBox(height: 6),
        TextField(
          obscureText: obscure,
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.textKey);
  final String textKey;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 16,
            color: AppColors.success,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.t.t(textKey),
              style: AppTypography.bodyMedium,
            ),
          ),
        ],
      ),
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
