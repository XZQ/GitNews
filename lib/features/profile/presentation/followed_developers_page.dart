import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/domain/contributor_entity.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/shared/local_content_controller.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../../../shared/widgets/secondary_page_scaffold.dart';
import 'widgets/collection_page_controls.dart';

class FollowedDevelopersPage extends StatelessWidget {
  const FollowedDevelopersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SecondaryPageScaffold(
      title: l10n.tr('profile.collection.developers.title'),
      icon: Icons.people_alt_rounded,
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
    final developers = <ContributorEntity>[
      for (final id in content.followedDevelopers)
        if (content.followedDeveloperSnapshots[id] case final snapshot?) snapshot.toEntity(),
    ];
    if (developers.isEmpty) {
      return EmptyView(
        icon: Icons.person_add_outlined,
        message: l10n.tr('profile.collection.developers.empty'),
        action: FilledButton(
          onPressed: () => context.go('/discover'),
          child: Text(l10n.tr('profile.collection.discover_action')),
        ),
      );
    }
    final query = _query.trim().toLowerCase();
    final filtered = query.isEmpty ? developers : developers.where((developer) => developer.login.toLowerCase().contains(query)).toList(growable: false);
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
            countLabel: l10n.tr('profile.collection.developers.count').replaceAll('{n}', '${filtered.length}'),
            searchHint: l10n.tr('profile.collection.search_developers'),
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
                    final developer = filtered[index];
                    return AppCard(
                      padding: EdgeInsets.zero,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Color(developer.avatarAccentArgb).withValues(alpha: 0.16),
                          child: Text(
                            developer.login[0].toUpperCase(),
                            style: AppTypography.titleSmall.copyWith(
                              color: Color(developer.avatarAccentArgb),
                            ),
                          ),
                        ),
                        title: Text(
                          developer.login,
                          style: AppTypography.titleSmall,
                        ),
                        subtitle: Text(
                          l10n
                              .tr(
                                'profile.collection.developers.contribution',
                              )
                              .replaceAll(
                                '{n}',
                                '${developer.contributions}',
                              ),
                        ),
                        trailing: IconButton(
                          tooltip: l10n.tr('a11y.developer_unfollow').replaceAll('{name}', developer.login),
                          icon: const Icon(Icons.person_remove_outlined),
                          onPressed: () => _unfollow(developer),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _unfollow(ContributorEntity developer) {
    final l10n = AppLocalizations.of(context);
    ref.read(localContentControllerProvider.notifier).toggleDeveloper(developer);
    final messenger = ScaffoldMessenger.of(context)..clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.tr('profile.collection.developer_removed')),
        action: SnackBarAction(
          label: l10n.tr('common.undo'),
          onPressed: () => ref.read(localContentControllerProvider.notifier).toggleDeveloper(developer),
        ),
      ),
    );
  }
}
