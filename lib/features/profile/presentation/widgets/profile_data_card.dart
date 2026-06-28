import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/section_header.dart';
import 'profile_atoms.dart';

class ProfileDataCard extends StatelessWidget {
  const ProfileDataCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: '数据与缓存',
            subtitle: '本地数据管理',
          ),
          const SizedBox(height: AppSpacing.md),
          const ProfileDataRow(label: '主题(2 分钟更新)', value: '12.8 MB'),
          const ProfileDataRow(label: '主题主题(7 天)', value: '156 MB'),
          const ProfileDataRow(label: '主题(30 天)', value: '624 MB'),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('已清理缓存(模拟)')),
                );
              },
              icon: const Icon(Icons.cleaning_services_outlined, size: 16),
              label: const Text('清理缓存'),
            ),
          ),
        ],
      ),
    );
  }
}
