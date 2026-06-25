import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
        title: const Text('登录'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
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

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        AppCard(
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: '登录 GitHub',
                subtitle: '解锁数据同步、跨设备、监控告警推送',
              ),
              SizedBox(height: AppSpacing.lg),
              _InputField(
                label: '用户名 / 邮箱',
                hint: 'your-name',
              ),
              SizedBox(height: AppSpacing.md),
              _InputField(
                label: '密码',
                hint: '********',
                obscure: true,
              ),
              SizedBox(height: AppSpacing.lg),
            ],
          ).copyChildren([
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {},
                child: const Text('登录'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.code, size: 16),
                label: const Text('使用 GitHub 登录'),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: Text(
                '登录即代表同意《服务条款》与《隐私政策》',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textMutedLight,
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(height: AppSpacing.lg),
        const AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: '为什么登录?',
                subtitle: '匿名也能使用大部分功能',
              ),
              SizedBox(height: AppSpacing.md),
              _Bullet('同步监控规则与告警'),
              _Bullet('跨设备访问'),
              _Bullet('GitHub API 配额提升至 5000/h'),
            ],
          ),
        ),
      ],
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.label,
    required this.hint,
    this.obscure = false,
  });

  final String label;
  final String hint;
  final bool obscure;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.labelMedium),
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
  const _Bullet(this.text);

  final String text;

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
