import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/demo_data.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_card.dart';
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
                  subtitle: '${'共'} ${DemoData.contributors.length}',
                ),
              ),
              for (var i = 0; i < DemoData.contributors.length; i++) ...[
                if (i != 0) const Divider(height: 1),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Color(
                      DemoData.contributors[i].avatarColor,
                    ).withValues(alpha: 0.16),
                    child: Text(
                      DemoData.contributors[i].login[0].toUpperCase(),
                      style: AppTypography.titleSmall.copyWith(
                        color: Color(
                          DemoData.contributors[i].avatarColor,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    DemoData.contributors[i].login,
                    style: AppTypography.titleSmall,
                  ),
                  subtitle: Text(
                    '+${DemoData.contributors[i].contributions} ${'本周贡献'}',
                  ),
                  trailing: OutlinedButton(
                    onPressed: () {},
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
