import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/shared/local_content_controller.dart';
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
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tr('profile.collection.developers.title')), leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go('/profile'))),
      body: ResponsiveLayout(compact: (_) => const _Body(), medium: (_) => const CenteredContent(child: _Body()), expanded: (_) => const CenteredContent(child: _Body())),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final content = ref.watch(localContentControllerProvider);
    final devs = [
      for (final id in content.followedDevelopers)
        if (content.followedDeveloperSnapshots[id] case final snapshot?) snapshot.toEntity()
    ];
    if (devs.isEmpty) {
      return EmptyView(icon: Icons.person_add_outlined, message: l10n.tr('profile.collection.developers.empty'));
    }
    return ListView(padding: const EdgeInsets.all(AppSpacing.lg), children: [
      AppCard(
          padding: EdgeInsets.zero,
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xs),
              child: SectionHeader(title: l10n.tr('profile.collection.developers.title'), subtitle: l10n.tr('profile.collection.developers.count').replaceAll('{n}', '${devs.length}')),
            ),
            for (var i = 0; i < devs.length; i++) ...[
              if (i != 0) const Divider(height: 1),
              ListTile(
                leading: Semantics(
                  image: true,
                  label: l10n.tr('a11y.developer_avatar').replaceAll('{name}', devs[i].login),
                  child: ExcludeSemantics(
                    child: CircleAvatar(
                      backgroundColor: Color(devs[i].avatarAccentArgb).withValues(alpha: 0.16),
                      child: Text(devs[i].login[0].toUpperCase(), style: AppTypography.titleSmall.copyWith(color: Color(devs[i].avatarAccentArgb))),
                    ),
                  ),
                ),
                title: Text(devs[i].login, style: AppTypography.titleSmall),
                subtitle: Text(l10n.tr('profile.collection.developers.contribution').replaceAll('{n}', '${devs[i].contributions}')),
                trailing: Semantics(
                  button: true,
                  label: l10n.tr('a11y.developer_unfollow').replaceAll('{name}', devs[i].login),
                  child: OutlinedButton(onPressed: () => ref.read(localContentControllerProvider.notifier).toggleDeveloper(devs[i]), child: Text(l10n.tr('profile.collection.developers.unfollow'))),
                ),
              )
            ]
          ]))
    ]);
  }
}
