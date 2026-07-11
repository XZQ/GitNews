import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/shared/local_content_controller.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/repo_tile.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../../shared/widgets/section_header.dart';

class CollectPage extends StatelessWidget {
  const CollectPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('收藏的主题'),
        leading: BackButton(
          onPressed: () => context.canPop() ? context.pop() : context.go('/profile'),
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
    final l10n = AppLocalizations.of(context);
    final content = ref.watch(localContentControllerProvider);
    final repos = [
      for (final id in content.bookmarkedRepos)
        if (content.bookmarkedRepoSnapshots[id] case final snapshot?) snapshot.toEntity(),
    ];
    if (repos.isEmpty) {
      return const EmptyView(
        icon: Icons.bookmark_border_rounded,
        message: '还没有收藏的主题',
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
                  title: '收藏的主题',
                  subtitle: '共 ${repos.length} 个',
                ),
              ),
              for (var i = 0; i < repos.length; i++) ...[
                if (i != 0) const Divider(height: 1),
                Row(
                  children: [
                    Expanded(
                      child: RepoTile(
                        repo: repos[i],
                        onTap: () => context.go(
                          '/profile/detail/${Uri.encodeComponent(repos[i].fullName)}',
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.tr('a11y.bookmark_remove'),
                      icon: const Icon(Icons.bookmark_remove_outlined),
                      onPressed: () => ref.read(localContentControllerProvider.notifier).removeBookmark(repos[i].fullName),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
