import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/section_header.dart';
import 'profile_atoms.dart';

class ProfileAboutCard extends StatelessWidget {
  const ProfileAboutCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: '关于',
            subtitle: 'GitHub 开发者情报',
          ),
          SizedBox(height: AppSpacing.md),
          ProfileAboutRow(label: '版本', value: '0.1.0'),
          ProfileAboutRow(label: '构建', value: '2026-06-23'),
          ProfileAboutRow(label: '官方网站', value: 'github-news.app'),
        ],
      ),
    );
  }
}
