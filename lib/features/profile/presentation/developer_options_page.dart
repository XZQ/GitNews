import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../../shared/widgets/section_header.dart';
import 'widgets/github_token_card.dart';

class DeveloperOptionsPage extends ConsumerWidget {
  const DeveloperOptionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('开发者选项'), leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go('/profile'))),
      body: ResponsiveLayout(compact: (_) => const _Body(), medium: (_) => const CenteredContent(child: _Body()), expanded: (_) => const CenteredContent(child: _Body())),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: const [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(title: 'API 调试', subtitle: '开发者工具'),
              SizedBox(height: AppSpacing.md),
              _Row(label: 'GitHub API 端点', value: 'api.github.com'),
              _Row(label: '请求超时', value: '10s'),
              _Row(label: '重试次数', value: '2'),
              _Row(label: '当前主题', value: '浅色')
            ],
          ),
        ),
        SizedBox(height: AppSpacing.lg),
        GitHubTokenCard(),
        SizedBox(height: AppSpacing.lg),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(title: '实验功能', subtitle: '可能不稳定'),
              SizedBox(height: AppSpacing.md),
              _Row(label: '新缓存策略', value: 'OFF'),
              _Row(label: '实时趋势', value: 'OFF'),
              _Row(label: 'AI 总结', value: 'BETA')
            ],
          ),
        )
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
        children: [Expanded(child: Text(label, style: AppTypography.bodyMedium.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant))), Text(value, style: AppTypography.labelMedium)],
      ),
    );
  }
}
