import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_card.dart';

/// 手机端聚合卡:收藏 + 关注开发者。
class ProfileCollectListCard extends StatelessWidget {
  const ProfileCollectListCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.bookmark_outline, color: AppColors.info),
            title: const Text('收藏的主题', style: AppTypography.titleMedium),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: () => context.go('/profile/collect'),
          ),
          const Divider(height: 1),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.people_outline, color: AppColors.success),
            title: const Text('关注的开发者', style: AppTypography.titleMedium),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: () => context.go('/profile/developers'),
          ),
        ],
      ),
    );
  }
}

/// 手机端聚合卡:监控主题 + 监控规则。
class ProfileMonitorListCard extends StatelessWidget {
  const ProfileMonitorListCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.visibility_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('监控的主题', style: AppTypography.titleMedium),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: () => context.go('/profile/monitor'),
          ),
          const Divider(height: 1),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.bolt_rounded, color: AppColors.warning),
            title: const Text('监控规则', style: AppTypography.titleMedium),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: () => context.go('/profile/rules'),
          ),
        ],
      ),
    );
  }
}
