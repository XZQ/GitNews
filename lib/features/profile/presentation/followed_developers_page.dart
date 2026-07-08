import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/demo_data.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../../shared/widgets/section_header.dart';
import '../application/local_content_controller.dart';

class FollowedDevelopersPage extends StatelessWidget {
  const FollowedDevelopersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('关注的开发者'),
        leading: BackButton(
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

class _Body extends ConsumerWidget {
  const _Body();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = ref.watch(localContentControllerProvider);
    final devs = [
      for (final dev in DemoData.contributors)
        if (content.isFollowingDeveloper(dev.login)) dev,
    ];
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
                  subtitle: '共 ${devs.length} 位',
                ),
              ),
              for (var i = 0; i < devs.length; i++) ...[
                if (i != 0) const Divider(height: 1),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        Color(devs[i].avatarColor).withValues(alpha: 0.16),
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
                    onPressed: () => ref
                        .read(localContentControllerProvider.notifier)
                        .toggleDeveloper(devs[i].login),
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
