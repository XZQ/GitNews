import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/preferences/profile_session_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../../shared/widgets/section_header.dart';

/* 
*登录页(预留入口,匿名优先)。
*/
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tr('profile.login')),
        leading: BackButton(
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/profile'),
        ),
      ),
      body: ResponsiveLayout(
        compact: (_) => const _Body(),
        medium: (_) => const CenteredContent(maxWidth: 480, child: _Body()),
        expanded: (_) => const CenteredContent(maxWidth: 480, child: _Body()),
      ),
    );
  }
}

class _Body extends ConsumerStatefulWidget {
  const _Body();

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  late final TextEditingController _nameController;
  late final TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: ref.read(profileSessionControllerProvider).effectiveName,
    );
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

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
              SectionHeader(
                title: l10n.tr('profile.login_github'),
                subtitle: l10n.tr('profile.login_github.subtitle'),
              ),
              const SizedBox(height: AppSpacing.lg),
              _InputField(
                label: l10n.tr('profile.login.username_hint'),
                hint: 'your-name',
                controller: _nameController,
              ),
              const SizedBox(height: AppSpacing.md),
              _InputField(
                label: l10n.tr('profile.login.password'),
                hint: '********',
                controller: _passwordController,
                obscure: true,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ).copyChildren([
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _signIn,
                child: Text(l10n.tr('profile.login.button')),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.go('/profile/developer'),
                icon: const Icon(Icons.code, size: 16),
                label: Text(l10n.tr('profile.login.with_github')),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: Text(
                l10n.tr('profile.login.disclaimer'),
                style: AppTypography.labelSmall.copyWith(
                  color: Theme.of(context).brightness == Brightness.light
                      ? AppColors.textMutedLight
                      : AppColors.textMutedDark,
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
                title: l10n.tr('profile.login.why_login'),
                subtitle: l10n.tr('profile.login.why_login.subtitle'),
              ),
              const SizedBox(height: AppSpacing.md),
              _Bullet(l10n.tr('profile.login.bullet.sync')),
              _Bullet(l10n.tr('profile.login.bullet.cross_device')),
              _Bullet(l10n.tr('profile.login.bullet.api_quota')),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _signIn() async {
    final l10n = AppLocalizations.of(context);
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入用户名或邮箱')),
      );
      return;
    }
    await ref.read(profileSessionControllerProvider.notifier).signInLocal(name);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${l10n.tr('profile.login.button')}成功')),
    );
    context.go('/profile');
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.label,
    required this.hint,
    required this.controller,
    this.obscure = false,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final bool obscure;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.labelMedium),
        const SizedBox(height: AppSpacing.xs2),
        TextField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(hintText: hint),
        ),
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
          Expanded(
            child: Text(
              text,
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
