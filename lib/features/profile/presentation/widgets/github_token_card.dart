import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/preferences/github_token_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../application/github_rate_limit_providers.dart';
import '../../data/github_rate_limit_client.dart';

class GitHubTokenCard extends ConsumerStatefulWidget {
  const GitHubTokenCard({super.key});

  @override
  ConsumerState<GitHubTokenCard> createState() => _GitHubTokenCardState();
}

class _GitHubTokenCardState extends ConsumerState<GitHubTokenCard> {
  late final TextEditingController _controller;
  AsyncValue<GitHubRateLimitSnapshot>? _rateLimit;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokenState = ref.watch(githubTokenControllerProvider);
    final colors = Theme.of(context).colorScheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'GitHub Token',
            subtitle: '用于 GitHub Search 认证请求,提升配额稳定性',
            trailing: _StatusPill(
              label: tokenState.hasToken ? tokenState.maskedToken : '未配置',
              active: tokenState.hasToken,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _controller,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Personal Access Token',
              hintText: 'github_pat_... 或 ghp_...',
            ),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Token 只用于本机请求 GitHub API。当前版本保存到本地偏好配置,后续可替换为安全存储或 OAuth。',
            style: AppTypography.labelSmall.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_outlined, size: 16),
                label: const Text('保存'),
              ),
              const SizedBox(width: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: tokenState.hasToken ? _clear : null,
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('清除'),
              ),
              const SizedBox(width: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: _rateLimit?.isLoading == true ? null : _checkQuota,
                icon: const Icon(Icons.speed_rounded, size: 16),
                label: const Text('检查配额'),
              ),
            ],
          ),
          if (_rateLimit != null) ...[
            const SizedBox(height: AppSpacing.md),
            _RateLimitStatus(value: _rateLimit!),
          ],
        ],
      ),
    );
  }

  Future<void> _save() async {
    await ref
        .read(githubTokenControllerProvider.notifier)
        .setToken(_controller.text);
    _controller.clear();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('GitHub Token 已保存')),
    );
  }

  Future<void> _clear() async {
    await ref.read(githubTokenControllerProvider.notifier).clear();
    _controller.clear();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('GitHub Token 已清除')),
    );
  }

  Future<void> _checkQuota() async {
    setState(() => _rateLimit = const AsyncLoading());
    try {
      final token = ref.read(githubTokenControllerProvider).token;
      final snapshot =
          await ref.read(githubRateLimitClientProvider).fetch(token: token);
      if (!mounted) return;
      setState(() => _rateLimit = AsyncData(snapshot));
    } catch (e, st) {
      if (!mounted) return;
      setState(() => _rateLimit = AsyncError(e, st));
    }
  }
}

class _RateLimitStatus extends StatelessWidget {
  const _RateLimitStatus({required this.value});

  final AsyncValue<GitHubRateLimitSnapshot> value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return value.when(
      loading: () => Row(
        children: [
          SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '正在检查 GitHub 配额...',
            style: AppTypography.labelMedium.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
      error: (_, __) => Text(
        '检查失败,请确认网络或 Token 是否有效',
        style: AppTypography.labelMedium.copyWith(color: AppColors.danger),
      ),
      data: (snapshot) => Column(
        children: [
          _QuotaRow(label: 'REST Core', bucket: snapshot.core),
          const SizedBox(height: AppSpacing.xs),
          _QuotaRow(label: 'Search API', bucket: snapshot.search),
          const SizedBox(height: AppSpacing.xs),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '检查时间 ${_formatTime(snapshot.checkedAt)}',
              style: AppTypography.labelSmall.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuotaRow extends StatelessWidget {
  const _QuotaRow({required this.label, required this.bucket});

  final String label;
  final GitHubRateLimitBucket bucket;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final ratio = bucket.limit == 0 ? 0.0 : bucket.remaining / bucket.limit;
    final accent = ratio > 0.35 ? AppColors.success : AppColors.warning;
    return Row(
      children: [
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: ratio.clamp(0, 1),
              minHeight: 7,
              color: accent,
              backgroundColor: colors.surfaceContainerHighest,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '${bucket.remaining}/${bucket.limit}',
          style: AppTypography.labelMedium.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          _formatTime(bucket.resetAt),
          style: AppTypography.labelSmall.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

String _formatTime(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.success : AppColors.textMutedLight;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
