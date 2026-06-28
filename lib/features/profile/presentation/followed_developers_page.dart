import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/demo_data.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../../shared/widgets/section_header.dart';

class FollowedDevelopersPage extends StatelessWidget {
  const FollowedDevelopersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('关注的开发者'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/profile'),
        ),
      ),
      body: ResponsiveLayout(
        compact: (_) => const _Body(),
        medium: (_) => const CenteredContent(child: _Body()),
        expanded: (_) => const CenteredContent(child: _Body()),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    const devs = DemoData.contributors;
    if (devs.isEmpty) {
      return const EmptyView(
        icon: Icons.person_add_outlined,
        message: '还没有关注的开发者',
      );
    }
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.xs,
                ),
                child: SectionHeader(
                  title: '关注的开发者',
                  subtitle: '共 ${devs.length}',
                ),
              ),
              for (var i = 0; i < devs.length; i++) ...[
                if (i != 0) const Divider(height: 1),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Color(
                      devs[i].avatarColor,
                    ).withValues(alpha: 0.16),
                    child: Text(
                      devs[i].login[0].toUpperCase(),
                      style: AppTypography.titleSmall.copyWith(
                        color: Color(devs[i].avatarColor),
                      ),
                    ),
                  ),
                  title: Text(devs[i].login, style: AppTypography.titleSmall),
                  subtitle: Text('+${devs[i].contributions} 本周贡献'),
                  trailing: OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('已取消关注 @${devs[i].login}')),
                      );
                    },
                    child: const Text('取消关注'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
