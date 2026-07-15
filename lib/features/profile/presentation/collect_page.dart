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
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tr('profile.collection.starred.title')), leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go('/profile'))),
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
        if (content.bookmarkedRepoSnapshots[id] case final snapshot?) snapshot.toEntity()
    ];
    if (repos.isEmpty) {
      return EmptyView(icon: Icons.bookmark_border_rounded, message: l10n.tr('profile.collection.starred.empty'));
    }
    return ListView(padding: const EdgeInsets.all(AppSpacing.lg), children: [
      AppCard(
          padding: EdgeInsets.zero,
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xs,
              ),
              child: SectionHeader(title: l10n.tr('profile.collection.starred.title'), subtitle: l10n.tr('profile.collection.starred.count').replaceAll('{n}', '${repos.length}')),
            ),
            Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.xs,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: Column(children: [
                  for (var i = 0; i < repos.length; i++) ...[
                    if (i != 0) const SizedBox(height: AppSpacing.sm),
                    RepoTile(
                      repo: repos[i],
                      onTap: () => context.go('/profile/detail/${Uri.encodeComponent(repos[i].fullName)}'),
                      trailing: Semantics(
                        container: true,
                        button: true,
                        label: l10n.tr('a11y.bookmark_remove'),
                        excludeSemantics: true,
                        child: IconButton(
                          tooltip: l10n.tr('a11y.bookmark_remove'),
                          icon: const Icon(Icons.bookmark_remove_outlined),
                          onPressed: () => ref.read(localContentControllerProvider.notifier).removeBookmark(repos[i].fullName),
                        ),
                      ),
                    )
                  ]
                ]))
          ]))
    ]);
  }
}
