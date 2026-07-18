import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/domain/repo_entity.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/shared/local_content_controller.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/repo_tile.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../../shared/widgets/secondary_page_scaffold.dart';
import 'widgets/collection_page_controls.dart';

class CollectPage extends StatelessWidget {
  const CollectPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SecondaryPageScaffold(
      title: l10n.tr('profile.collection.starred.title'),
      icon: Icons.bookmark_rounded,
      fallbackPath: '/profile',
      body: ResponsiveLayout(
        compact: (_) => const _Body(),
        medium: (_) => const CenteredContent(child: _Body()),
        expanded: (_) => const CenteredContent(child: _Body()),
      ),
    );
  }
}

class _Body extends ConsumerStatefulWidget {
  const _Body();

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final content = ref.watch(localContentControllerProvider);
    final repos = [
      for (final id in content.bookmarkedRepos)
        if (content.bookmarkedRepoSnapshots[id] case final snapshot?) snapshot.toEntity(),
    ];
    if (repos.isEmpty) {
      return EmptyView(
        icon: Icons.bookmark_border_rounded,
        message: l10n.tr('profile.collection.starred.empty'),
        action: FilledButton(
          onPressed: () => context.go('/discover'),
          child: Text(l10n.tr('profile.collection.discover_action')),
        ),
      );
    }
    final query = _query.trim().toLowerCase();
    final filtered = query.isEmpty
        ? repos
        : repos
            .where(
              (repo) => [repo.fullName, repo.description, repo.language].join(' ').toLowerCase().contains(query),
            )
            .toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: CollectionPageControls(
            countLabel: l10n.tr('profile.collection.starred.count').replaceAll('{n}', '${filtered.length}'),
            searchHint: l10n.tr('profile.collection.search_repos'),
            onChanged: (value) => setState(() => _query = value),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? EmptyView(
                  icon: Icons.search_off_rounded,
                  message: l10n.tr('profile.collection.no_match'),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.xs,
                    AppSpacing.lg,
                    AppSpacing.xxxl,
                  ),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final repo = filtered[index];
                    return AppCard(
                      padding: EdgeInsets.zero,
                      child: RepoTile(
                        repo: repo,
                        card: false,
                        dense: true,
                        onTap: () => context.go(
                          '/profile/detail/${Uri.encodeComponent(repo.fullName)}',
                        ),
                        trailing: Semantics(
                          container: true,
                          button: true,
                          label: l10n.tr('a11y.bookmark_remove'),
                          excludeSemantics: true,
                          child: IconButton(
                            tooltip: l10n.tr('a11y.bookmark_remove'),
                            icon: const Icon(Icons.bookmark_remove_outlined),
                            onPressed: () => _removeBookmark(repo),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _removeBookmark(RepoEntity repo) {
    final l10n = AppLocalizations.of(context);
    ref.read(localContentControllerProvider.notifier).removeBookmark(repo.fullName);
    final messenger = ScaffoldMessenger.of(context)..clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.tr('profile.collection.bookmark_removed')),
        action: SnackBarAction(
          label: l10n.tr('common.undo'),
          onPressed: () => ref.read(localContentControllerProvider.notifier).toggleBookmark(repo),
        ),
      ),
    );
  }
}
