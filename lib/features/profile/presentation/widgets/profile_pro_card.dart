import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/section_header.dart';
import 'profile_atoms.dart';

class ProfileProCard extends StatelessWidget {
  const ProfileProCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'GitHub 开发者情报 PRO',
            subtitle: '解锁全部高级功能',
          ),
          const SizedBox(height: AppSpacing.md),
          const ProfileBullet('无限监控仓库'),
          const ProfileBullet('高级告警与每日报告'),
          const ProfileBullet('GitHub 与 Gitee 数据导出'),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PRO 服务尚未上线,敬请期待')),
                );
              },
              child: const Text('升级 PRO'),
            ),
          ),
        ],
      ),
    );
  }
}
