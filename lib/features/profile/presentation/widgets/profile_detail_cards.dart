import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/section_header.dart';
import 'profile_atoms.dart';

class ProfileCollectDetailCard extends StatelessWidget {
  const ProfileCollectDetailCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: '收藏的主题',
            subtitle: '你长期追踪的 GitHub 主题',
          ),
          const SizedBox(height: AppSpacing.md),
          const ProfileDetailRow(
            icon: Icons.bookmark_outline,
            iconColor: AppColors.info,
            label: '收藏主题 (12)',
            value: '全部',
          ),
          const Divider(height: 1),
          const ProfileDetailRow(
            icon: Icons.history,
            iconColor: AppColors.textSecondaryLight,
            label: '最近收藏',
            value: 'agent · llm · devops',
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: () => context.go('/profile/collect'),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('打开收藏页'),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileDevelopersDetailCard extends StatelessWidget {
  const ProfileDevelopersDetailCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: '关注的开发者',
            subtitle: '第一时间拿到他们的最新动态',
          ),
          const SizedBox(height: AppSpacing.md),
          const ProfileDetailRow(
            icon: Icons.people_outline,
            iconColor: AppColors.success,
            label: '关注开发者 (8)',
            value: '全部',
          ),
          const Divider(height: 1),
          const ProfileDetailRow(
            icon: Icons.notifications_active_outlined,
            iconColor: AppColors.warning,
            label: '通知策略',
            value: 'Star / Fork / Release',
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: () => context.go('/profile/developers'),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('打开开发者页'),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileMonitorTopicsDetailCard extends StatelessWidget {
  const ProfileMonitorTopicsDetailCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: '监控的主题',
            subtitle: '持续追踪仓库的 Star / Issue / Release',
          ),
          const SizedBox(height: AppSpacing.md),
          ProfileDetailRow(
            icon: Icons.visibility_outlined,
            iconColor: Theme.of(context).colorScheme.primary,
            label: '正在监控 (5)',
            value: '全部',
          ),
          const Divider(height: 1),
          const ProfileDetailRow(
            icon: Icons.timeline,
            iconColor: AppColors.info,
            label: '最新告警',
            value: '2 条未读',
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: () => context.go('/profile/monitor'),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('打开监控主题'),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileMonitorRulesDetailCard extends StatelessWidget {
  const ProfileMonitorRulesDetailCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: '监控规则',
            subtitle: '自定义告警触发条件',
          ),
          const SizedBox(height: AppSpacing.md),
          const ProfileDetailRow(
            icon: Icons.bolt_rounded,
            iconColor: AppColors.warning,
            label: 'Star 增速 ≥ 30 / 天',
            value: '已启用',
          ),
          const Divider(height: 1),
          const ProfileDetailRow(
            icon: Icons.bolt_rounded,
            iconColor: AppColors.warning,
            label: 'Issue 数小时 ≥ 5',
            value: '已启用',
          ),
          const Divider(height: 1),
          const ProfileDetailRow(
            icon: Icons.bolt_rounded,
            iconColor: AppColors.warning,
            label: '新 Release',
            value: '已启用',
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: () => context.go('/profile/rules'),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('管理规则'),
            ),
          ),
        ],
      ),
    );
  }
}
