import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/webview/presentation/webview_page.dart';
import '../../shared/widgets/responsive_scaffold.dart';
import '../preferences/startup_tab_controller.dart';
import 'app_route_branches.dart';
import 'route_error_view.dart';

export 'route_specs.dart';

final appRouterProvider = Provider<GoRouter>(buildAppRouter);

GoRouter buildAppRouter(Ref ref) {
  final startupSegment = ref.read(startupTabControllerProvider);
  return GoRouter(
    initialLocation: '/$startupSegment',
    debugLogDiagnostics: false,
    routes: [
      StatefulShellRoute.indexedStack(builder: (_, __, navigationShell) => ResponsiveScaffold(navigationShell: navigationShell), branches: buildAppRouteBranches()),
      GoRoute(path: '/login', name: 'login', redirect: (_, __) => '/profile/login'),
      GoRoute(
        path: '/webview',
        name: 'webview',
        builder: (_, state) => WebViewPage(url: state.uri.queryParameters['url'] ?? '', title: state.uri.queryParameters['title']),
      )
    ],
    errorBuilder: (context, state) => RouteErrorView(error: state.error),
  );
}
