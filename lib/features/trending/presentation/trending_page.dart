import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/utils/breakpoint.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/responsive_layout.dart';
import '../application/trending_providers.dart';
import '../widgets/trending_desktop_view.dart';
import '../widgets/trending_mobile_view.dart';
import '../widgets/trending_skeleton.dart';

class TrendingPage extends ConsumerWidget {
  const TrendingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isCompact = Breakpoints.isCompact(context);
    final state = ref.watch(trendingDigestProvider);
    return Scaffold(
      appBar: isCompact ? AppBar(title: Text(l10n.tr('trending.title'))) : null,
      body: state.when(
        data: (digest) {
          if (digest.isEmpty) {
            return EmptyView(
              icon: Icons.local_fire_department_outlined,
              message: l10n.tr('trending.empty'),
            );
          }
          return ResponsiveLayout(
            compact: (_) => TrendingMobileView(digest: digest),
            medium: (_) => TrendingDesktopView(digest: digest),
            expanded: (_) => TrendingDesktopView(digest: digest),
          );
        },
        loading: () => const TrendingSkeleton(),
        error: (error, stackTrace) => ErrorView(
          error: error.asAppException(stackTrace),
          onRetry: () => ref.invalidate(trendingDigestProvider),
        ),
      ),
    );
  }
}
