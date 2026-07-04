import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/section_header.dart';
import 'profile_atoms.dart';

class ProfileProCard extends StatelessWidget {
  const ProfileProCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: l10n.tr('profile.pro.title'),
            subtitle: l10n.tr('profile.pro.subtitle'),
          ),
          const SizedBox(height: AppSpacing.md),
          ProfileBullet(l10n.tr('profile.pro.bullet.unlimited')),
          ProfileBullet(l10n.tr('profile.pro.bullet.alerts')),
          ProfileBullet(l10n.tr('profile.pro.bullet.export')),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => _showProPanel(context),
              child: Text(l10n.tr('profile.pro.upgrade')),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _showProPanel(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(
                title: 'PRO 能力中心',
                subtitle: '当前版本已开放的本地增强能力',
              ),
              const SizedBox(height: AppSpacing.md),
              const _CapabilityRow(
                icon: Icons.key_rounded,
                title: 'GitHub Token 配额增强',
                subtitle: '提升 GitHub Search 稳定性并查看剩余额度',
              ),
              const _CapabilityRow(
                icon: Icons.download_rounded,
                title: '深度报告 Markdown 导出',
                subtitle: '导出当前筛选后的报告数据到本机',
              ),
              const _CapabilityRow(
                icon: Icons.radar_rounded,
                title: '监控与告警工作台',
                subtitle: '统一查看监控仓库、告警和规则',
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        context.go('/profile/developer');
                      },
                      icon: const Icon(Icons.key_rounded, size: 16),
                      label: const Text('配置 Token'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        context.go('/project');
                      },
                      icon: const Icon(Icons.insights_rounded, size: 16),
                      label: const Text('打开报告'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _CapabilityRow extends StatelessWidget {
  const _CapabilityRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.success),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.labelLarge),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  subtitle,
                  style: AppTypography.labelSmall.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
